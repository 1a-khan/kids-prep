defmodule KidsPrep.Learning do
  import Ecto.Query

  require Logger

  alias KidsPrep.Learning.{DailyQuestionCache, Material, Question, Result}
  alias KidsPrep.Repo

  defdelegate children, to: Material
  defdelegate child!(slug), to: Material
  defdelegate subjects, to: Material
  defdelegate subject_label(subject), to: Material
  defdelegate notion_subject_label(subject), to: Material
  defdelegate subject_from_label(label), to: Material

  def daily_generated_questions(child_slug, subject, date \\ Date.utc_today()) do
    Material.daily_questions(child_slug, subject, date,
      level: adaptive_level(child_slug, subject)
    )
  end

  def daily_questions(child_slug, subject, date \\ Date.utc_today()) do
    cached_daily_questions(child_slug, subject, date) ||
      daily_generated_questions(child_slug, subject, date)
  end

  def daily_question_count(child_slug, subject, date \\ Date.utc_today()) do
    child_slug
    |> daily_questions(subject, date)
    |> length()
  end

  def refresh_daily_cache(date \\ Date.utc_today()) do
    for child_slug <- Map.keys(children()), subject <- subjects() do
      refresh_daily_cache(child_slug, subject, date)
    end
  end

  def refresh_daily_cache(child_slug, subject, date) do
    with {:ok, questions} <-
           KidsPrep.Notion.Sync.fetch_daily_questions(child_slug, subject, date),
         true <- Material.valid_questions_for_subject?(subject, questions),
         {:ok, cache} <- upsert_daily_cache(child_slug, subject, date, questions, "notion") do
      {:ok, cache}
    else
      false -> {:error, :invalid_language}
      {:error, reason} -> {:error, reason}
      error -> error
    end
  end

  def save_result(attrs) do
    %Result{}
    |> Result.changeset(attrs)
    |> Repo.insert()
    |> tap(fn
      {:ok, result} -> Task.start(fn -> sync_result_to_notion(result) end)
      _ -> :ok
    end)
  end

  def sync_result_to_notion(%Result{} = result) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case KidsPrep.Notion.Sync.push_result(result) do
      {:ok, _} ->
        update_result_sync_status(result, notion_synced_at: now, notion_sync_error: nil)

      error ->
        Logger.warning("Notion result sync failed for result #{result.id}: #{inspect(error)}")
        update_result_sync_status(result, notion_sync_error: inspect(error))
        {:error, error}
    end
  end

  def sync_unsynced_results(limit \\ 100) do
    Result
    |> where([r], is_nil(r.notion_synced_at))
    |> order_by([r], asc: r.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&sync_result_to_notion/1)
  end

  def recent_results(limit \\ 12) do
    Result
    |> order_by([r], desc: r.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def unsynced_result_count do
    Result
    |> where([r], is_nil(r.notion_synced_at))
    |> Repo.aggregate(:count)
  end

  def weak_skill_mistake_count(child_slug, subject, skill) do
    Result
    |> where([r], r.child_slug == ^child_slug and r.subject == ^subject)
    |> Repo.all()
    |> Enum.flat_map(&(get_in(&1.wrong_questions || %{}, ["items"]) || []))
    |> Enum.count(&(&1["skill"] == skill))
  end

  def performance_dashboard do
    results =
      Result
      |> order_by([r], asc: r.quiz_date, asc: r.inserted_at)
      |> Repo.all()

    %{
      children: dashboard_children(results),
      weak_skills: weak_skill_summary(results)
    }
  end

  def adaptive_level(child_slug, subject) do
    base_level = if child_slug == "mustafa", do: 2, else: 1

    recent =
      Result
      |> where([r], r.child_slug == ^child_slug and r.subject == ^subject)
      |> order_by([r], desc: r.quiz_date, desc: r.inserted_at)
      |> limit(3)
      |> Repo.all()

    if length(recent) >= 2 and average_percent(recent) >= 85 do
      min(base_level + 1, 3)
    else
      base_level
    end
  end

  defp dashboard_children(results) do
    children()
    |> Enum.map(fn {child_slug, child} ->
      child_results = Enum.filter(results, &(&1.child_slug == child_slug))

      subjects =
        subjects()
        |> Enum.map(fn subject ->
          subject_results = Enum.filter(child_results, &(&1.subject == subject))
          recent = subject_results |> Enum.reverse() |> Enum.take(5) |> Enum.reverse()

          %{
            subject: subject,
            label: subject_label(subject),
            attempts: length(subject_results),
            average: average_percent(subject_results),
            latest: subject_results |> List.last() |> result_percent(),
            level: adaptive_level(child_slug, subject),
            trend: Enum.map(recent, &result_percent/1)
          }
        end)

      %{
        slug: child_slug,
        name: child.name,
        attempts: length(child_results),
        average: average_percent(child_results),
        subjects: subjects
      }
    end)
  end

  defp weak_skill_summary(results) do
    results
    |> Enum.flat_map(fn result ->
      result.wrong_questions
      |> Map.get("items", [])
      |> Enum.map(fn item ->
        %{
          child: result.child_name,
          subject: result.subject,
          skill: item["skill"] || "Unbekannt"
        }
      end)
    end)
    |> Enum.group_by(&{&1.child, &1.subject, &1.skill})
    |> Enum.map(fn {{child, subject, skill}, items} ->
      %{
        child: child,
        subject: subject,
        label: subject_label(subject),
        skill: skill,
        count: length(items)
      }
    end)
    |> Enum.sort_by(& &1.count, :desc)
    |> Enum.take(8)
  end

  defp average_percent([]), do: 0

  defp average_percent(results) do
    results
    |> Enum.map(&result_percent/1)
    |> then(&(Enum.sum(&1) / length(&1)))
    |> round()
  end

  defp result_percent(nil), do: 0
  defp result_percent(%{total: total}) when total in [nil, 0], do: 0
  defp result_percent(%{score: score, total: total}), do: round(score / total * 100)

  defp cached_daily_questions(child_slug, subject, date) do
    DailyQuestionCache
    |> where([c], c.child_slug == ^child_slug and c.subject == ^subject and c.quiz_date == ^date)
    |> Repo.one()
    |> case do
      nil ->
        nil

      %DailyQuestionCache{questions: %{"items" => items}} ->
        questions = Enum.map(items, &map_to_question/1)

        if Material.valid_questions_for_subject?(subject, questions) do
          questions
        end

      _ ->
        nil
    end
  end

  defp upsert_daily_cache(child_slug, subject, date, questions, source) do
    attrs = %{
      child_slug: child_slug,
      subject: subject,
      quiz_date: date,
      questions: %{items: Enum.map(questions, &question_to_map/1)},
      source: source,
      synced_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    %DailyQuestionCache{}
    |> DailyQuestionCache.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:questions, :source, :synced_at, :updated_at]},
      conflict_target: [:child_slug, :subject, :quiz_date]
    )
  end

  defp map_to_question(attrs) do
    %Question{
      id: Map.fetch!(attrs, "id"),
      subject: Map.fetch!(attrs, "subject"),
      skill: Map.get(attrs, "skill"),
      level: Map.get(attrs, "level"),
      prompt: Map.fetch!(attrs, "prompt"),
      choices: Map.fetch!(attrs, "choices"),
      answer: Map.fetch!(attrs, "answer"),
      explanation: Map.fetch!(attrs, "explanation")
    }
  end

  defp question_to_map(question) do
    %{
      id: question.id,
      subject: question.subject,
      skill: question.skill,
      level: question.level,
      prompt: question.prompt,
      choices: question.choices,
      answer: question.answer,
      explanation: question.explanation
    }
  end

  defp update_result_sync_status(result, attrs) do
    result
    |> Result.changeset(Map.new(attrs))
    |> Repo.update()
  end
end

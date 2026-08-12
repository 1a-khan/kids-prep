defmodule KidsPrep.Learning do
  import Ecto.Query

  alias KidsPrep.Learning.{DailyQuestionCache, Material, Question, Result}
  alias KidsPrep.Repo

  defdelegate children, to: Material
  defdelegate child!(slug), to: Material
  defdelegate subjects, to: Material
  defdelegate subject_label(subject), to: Material
  defdelegate notion_subject_label(subject), to: Material
  defdelegate subject_from_label(label), to: Material

  defdelegate daily_generated_questions(child_slug, subject, date \\ Date.utc_today()),
    to: Material,
    as: :daily_questions

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
      {:ok, result} -> Task.start(fn -> KidsPrep.Notion.Sync.push_result(result) end)
      _ -> :ok
    end)
  end

  def recent_results(limit \\ 12) do
    Result
    |> order_by([r], desc: r.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

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
end

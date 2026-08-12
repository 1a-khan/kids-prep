defmodule KidsPrep.Learning do
  import Ecto.Query

  alias KidsPrep.Learning.{Material, Result}
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
    case KidsPrep.Notion.Sync.fetch_daily_questions(child_slug, subject, date) do
      {:ok, questions} ->
        if Material.valid_questions_for_subject?(subject, questions) do
          questions
        else
          daily_generated_questions(child_slug, subject, date)
        end

      _ ->
        daily_generated_questions(child_slug, subject, date)
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
end

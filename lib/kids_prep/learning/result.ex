defmodule KidsPrep.Learning.Result do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quiz_results" do
    field :child_slug, :string
    field :child_name, :string
    field :subject, :string
    field :quiz_date, :date
    field :score, :integer
    field :total, :integer
    field :duration_seconds, :integer
    field :wrong_questions, :map, default: %{"items" => []}
    field :answers, :map, default: %{"items" => []}
    field :notion_synced_at, :utc_datetime
    field :notion_sync_error, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :child_slug,
      :child_name,
      :subject,
      :quiz_date,
      :score,
      :total,
      :duration_seconds,
      :wrong_questions,
      :answers,
      :notion_synced_at,
      :notion_sync_error
    ])
    |> validate_required([:child_slug, :child_name, :subject, :quiz_date, :score, :total])
  end
end

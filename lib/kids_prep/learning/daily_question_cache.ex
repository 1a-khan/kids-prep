defmodule KidsPrep.Learning.DailyQuestionCache do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_question_caches" do
    field :child_slug, :string
    field :subject, :string
    field :quiz_date, :date
    field :questions, :map
    field :source, :string
    field :synced_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(cache, attrs) do
    cache
    |> cast(attrs, [:child_slug, :subject, :quiz_date, :questions, :source, :synced_at])
    |> validate_required([:child_slug, :subject, :quiz_date, :questions, :source, :synced_at])
    |> unique_constraint([:child_slug, :subject, :quiz_date])
  end
end

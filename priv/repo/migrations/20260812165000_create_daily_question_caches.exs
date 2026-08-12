defmodule KidsPrep.Repo.Migrations.CreateDailyQuestionCaches do
  use Ecto.Migration

  def change do
    create table(:daily_question_caches) do
      add(:child_slug, :string, null: false)
      add(:subject, :string, null: false)
      add(:quiz_date, :date, null: false)
      add(:questions, :map, null: false)
      add(:source, :string, null: false)
      add(:synced_at, :utc_datetime, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:daily_question_caches, [:child_slug, :subject, :quiz_date]))
  end
end

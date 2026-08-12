defmodule KidsPrep.Repo.Migrations.CreateQuizResults do
  use Ecto.Migration

  def change do
    create table(:quiz_results) do
      add(:child_slug, :string, null: false)
      add(:child_name, :string, null: false)
      add(:subject, :string, null: false)
      add(:quiz_date, :date, null: false)
      add(:score, :integer, null: false)
      add(:total, :integer, null: false)
      add(:duration_seconds, :integer)
      add(:wrong_questions, :map)
      add(:answers, :map)

      timestamps(type: :utc_datetime)
    end

    create(index(:quiz_results, [:child_slug, :subject, :quiz_date]))
  end
end

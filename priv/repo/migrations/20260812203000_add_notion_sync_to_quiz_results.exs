defmodule KidsPrep.Repo.Migrations.AddNotionSyncToQuizResults do
  use Ecto.Migration

  def change do
    alter table(:quiz_results) do
      add(:notion_synced_at, :utc_datetime)
      add(:notion_sync_error, :text)
    end

    create(index(:quiz_results, [:notion_synced_at]))
  end
end

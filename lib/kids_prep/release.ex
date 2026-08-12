defmodule KidsPrep.Release do
  @moduledoc false

  @app :kids_prep

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _apps, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _apps, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def repair_german_material do
    load_app()
    Application.ensure_all_started(@app)

    case KidsPrep.Notion.LanguageRepair.repair_german_material() do
      results when is_list(results) ->
        ok_count = Enum.count(results, &match?({:ok, _}, &1))
        error_count = length(results) - ok_count

        IO.puts("Repaired #{ok_count} Deutsch/Mathe Notion rows. Errors: #{error_count}.")

        results
        |> Enum.reject(&match?({:ok, _}, &1))
        |> Enum.each(&IO.puts(inspect(&1)))

      error ->
        IO.puts("Repair failed: #{inspect(error)}")
    end
  end

  def push_results_to_notion do
    load_app()
    Application.ensure_all_started(@app)

    results = KidsPrep.Learning.sync_unsynced_results(500)
    ok_count = Enum.count(results, &match?({:ok, _}, &1))
    error_count = length(results) - ok_count

    IO.puts("Synced #{ok_count} SQLite results to Notion. Errors: #{error_count}.")

    results
    |> Enum.reject(&match?({:ok, _}, &1))
    |> Enum.each(&IO.puts(inspect(&1)))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end

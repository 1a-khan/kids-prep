defmodule Mix.Tasks.KidsPrep.Notion.PushResults do
  use Mix.Task

  alias KidsPrep.{Learning, Notion}

  @shortdoc "Pushes recent SQLite results to Notion"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    if Notion.Sync.enabled?() do
      results = Learning.sync_unsynced_results(100)
      ok_count = Enum.count(results, &match?({:ok, _}, &1))
      error_count = length(results) - ok_count

      Mix.shell().info("Synced #{ok_count} SQLite results to Notion. Errors: #{error_count}.")

      results
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.each(&Mix.shell().error(inspect(&1)))
    else
      Mix.shell().error("Notion is not configured. Provide OpenBao credentials or NOTION_TOKEN.")
    end
  end
end

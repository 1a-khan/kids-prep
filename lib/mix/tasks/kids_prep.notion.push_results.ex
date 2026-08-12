defmodule Mix.Tasks.KidsPrep.Notion.PushResults do
  use Mix.Task

  alias KidsPrep.{Learning, Notion}

  @shortdoc "Pushes recent SQLite results to Notion"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    if Notion.Sync.enabled?() do
      Learning.recent_results(50)
      |> Enum.each(fn result ->
        Mix.shell().info("pushing result #{result.id} #{result.child_name} #{result.subject}")
        Notion.Sync.push_result(result)
      end)
    else
      Mix.shell().error(
        "NOTION_TOKEN is missing. Create an internal Notion integration and set NOTION_TOKEN."
      )
    end
  end
end

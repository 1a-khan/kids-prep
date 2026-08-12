defmodule Mix.Tasks.KidsPrep.Notion.GenerateDaily do
  use Mix.Task

  alias KidsPrep.Notion.Sync

  @shortdoc "Creates daily question modules in Notion"

  @moduledoc """
  Creates Notion question rows and daily module rows for a date.

      NOTION_TOKEN=notion_token_placeholder mix kids_prep.notion.generate_daily
      NOTION_TOKEN=notion_token_placeholder mix kids_prep.notion.generate_daily 2026-09-01
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    date =
      case args do
        [date] -> Date.from_iso8601!(date)
        _ -> Date.utc_today()
      end

    case Sync.ensure_daily_modules(date) do
      {:error, :notion_disabled} ->
        Mix.shell().error(
          "NOTION_TOKEN is missing. Create an internal Notion integration and set NOTION_TOKEN."
        )

      results when is_list(results) ->
        Mix.shell().info("Generated Notion daily modules for #{Date.to_iso8601(date)}")
        Enum.each(results, &Mix.shell().info(inspect(&1)))
    end
  end
end

defmodule Mix.Tasks.KidsPrep.Notion.RepairGermanMaterial do
  use Mix.Task

  alias KidsPrep.Notion.LanguageRepair

  @shortdoc "Repairs Deutsch and Mathe Notion material so learner text is German"

  @moduledoc """
  Repairs active Deutsch and Mathe rows in the Notion question bank.

  It keeps English-subject learning content in English, but rewrites Deutsch and
  Mathe prompts, skill labels, names, and explanations to German.

      mix kids_prep.notion.repair_german_material
  """

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    case LanguageRepair.repair_german_material() do
      {:error, :notion_disabled} ->
        Mix.shell().error(
          "Notion is not configured. Provide OpenBao credentials or NOTION_TOKEN."
        )

      results when is_list(results) ->
        ok_count = Enum.count(results, &match?({:ok, _}, &1))
        error_count = length(results) - ok_count

        Mix.shell().info(
          "Repaired #{ok_count} Deutsch/Mathe Notion rows. Errors: #{error_count}."
        )

        results
        |> Enum.reject(&match?({:ok, _}, &1))
        |> Enum.each(&Mix.shell().error(inspect(&1)))

      error ->
        Mix.shell().error("Repair failed: #{inspect(error)}")
    end
  end
end

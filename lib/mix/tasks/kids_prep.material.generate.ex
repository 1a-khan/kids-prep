defmodule Mix.Tasks.KidsPrep.Material.Generate do
  use Mix.Task

  alias KidsPrep.Learning

  @shortdoc "Writes daily question material to priv/generated_material"

  @moduledoc """
  Generates the deterministic daily material as JSON files.

      mix kids_prep.material.generate
      mix kids_prep.material.generate 2026-09-01

  This is the local helper for creating or reviewing new daily material.
  The website also generates the same question sets live from the selected date.
  """

  @impl true
  def run(args) do
    date =
      case args do
        [date] -> Date.from_iso8601!(date)
        _ -> Date.utc_today()
      end

    output_dir = Path.join(["priv", "generated_material", Date.to_iso8601(date)])
    File.mkdir_p!(output_dir)

    for child_slug <- Map.keys(Learning.children()), subject <- Learning.subjects() do
      questions =
        child_slug
        |> Learning.daily_questions(subject, date)
        |> Enum.map(&Map.from_struct/1)

      path = Path.join(output_dir, "#{child_slug}_#{subject}.json")
      File.write!(path, Jason.encode!(questions, pretty: true))
      Mix.shell().info("wrote #{path}")
    end
  end
end

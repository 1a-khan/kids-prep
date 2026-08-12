defmodule KidsPrep.Notion.LanguageRepairTest do
  use ExUnit.Case, async: true

  alias KidsPrep.Notion.LanguageRepair

  test "repairs German article prompt and explanation" do
    properties =
      repaired(%{
        "Subject" => "German",
        "Skill" => "Artikel",
        "Prompt" => "Which article belongs to 'Lampe'?",
        "Correct Answer" => "die",
        "Name" => "Mihrimah German Artikel"
      })

    assert text(properties, "Prompt") == "Welcher Artikel passt zu 'Lampe'?"

    assert text(properties, "Explanation") ==
             "Jedes deutsche Nomen hat einen Artikel. Sprich es als kleines Paket: 'die Lampe'."

    assert text(properties, "Skill") == "Artikel"
    assert title(properties, "Name") == "Mihrimah Deutsch Artikel"
  end

  test "repairs German verb and word order material" do
    verb =
      repaired(%{
        "Subject" => "German",
        "Skill" => "Verb endings",
        "Prompt" => "Choose the correct verb: sie ___ (trinken)",
        "Correct Answer" => "trinkt",
        "Name" => "Mustafa German Verb endings"
      })

    word_order =
      repaired(%{
        "Subject" => "German",
        "Skill" => "Word order",
        "Prompt" => "Build the best German sentence.",
        "Correct Answer" => "Morgen gehen wir zur Schule",
        "Name" => "Mustafa German Word order"
      })

    assert text(verb, "Prompt") == "Wähle das richtige Verb: sie ___ (trinken)"
    assert text(verb, "Skill") == "Verbendungen"
    assert text(verb, "Explanation") =~ "Zu 'sie' passt 'trinkt'"

    assert text(word_order, "Prompt") == "Baue den besten deutschen Satz."
    assert text(word_order, "Skill") == "Satzbau"
    assert text(word_order, "Explanation") =~ "Verb meistens an zweiter Stelle"
  end

  test "repairs Maths material in German" do
    addition =
      repaired(%{
        "Subject" => "Maths",
        "Skill" => "Addition",
        "Prompt" => "33 + 3 = ?",
        "Correct Answer" => "36",
        "Name" => "Mihrimah Maths Addition"
      })

    word_problem =
      repaired(%{
        "Subject" => "Maths",
        "Skill" => "Word problem",
        "Prompt" => "There are 16 apples. The family eats 5. How many are left?",
        "Correct Answer" => "11",
        "Name" => "Mihrimah Maths Word problem"
      })

    assert text(addition, "Skill") == "Plusrechnen"
    assert text(addition, "Explanation") =~ "Rechne zuerst die Zehner"

    assert text(word_problem, "Prompt") ==
             "Es gibt 16 Äpfel. Die Familie isst 5. Wie viele bleiben übrig?"

    assert text(word_problem, "Skill") == "Textaufgabe"
    assert text(word_problem, "Explanation") =~ "minus rechnen"
  end

  defp repaired(properties), do: LanguageRepair.repaired_properties(properties)

  defp text(properties, key) do
    properties
    |> get_in([key, :rich_text])
    |> Enum.map_join("", &get_in(&1, [:text, :content]))
  end

  defp title(properties, key) do
    properties
    |> get_in([key, :title])
    |> Enum.map_join("", &get_in(&1, [:text, :content]))
  end
end

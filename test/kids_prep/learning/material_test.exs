defmodule KidsPrep.Learning.MaterialTest do
  use ExUnit.Case, async: true

  alias KidsPrep.Learning.Material

  test "daily material exists for both children and every subject" do
    date = ~D[2026-08-12]

    for child <- Map.keys(Material.children()), subject <- Material.subjects() do
      questions = Material.daily_questions(child, subject, date)

      assert length(questions) >= 22
      assert Enum.all?(questions, &(&1.prompt != ""))
      assert Enum.all?(questions, &(length(&1.choices) >= 2))

      assert Enum.all?(
               questions,
               &Enum.member?(
                 Enum.map(&1.choices, fn choice -> to_string(choice) end),
                 to_string(&1.answer)
               )
             )
    end
  end

  test "english subject keeps questions and answers in English with German and Turkish explanations" do
    questions = Material.daily_questions("mustafa", "english", ~D[2026-08-12])

    vocabulary = Enum.find(questions, &(&1.skill == "Vocabulary"))
    reading = Enum.find(questions, &(&1.skill == "Reading"))

    assert vocabulary.prompt =~ "What does"
    assert "a kind of food" in vocabulary.choices
    assert vocabulary.explanation =~ "Deutsch:"
    assert vocabulary.explanation =~ "Türkçe:"

    assert reading.prompt =~ "What"
    assert reading.explanation =~ "Deutsch:"
    assert reading.explanation =~ "Türkçe:"
  end

  test "display labels are German while Notion labels remain compatible with existing databases" do
    assert Material.subject_label("english") == "Englisch"
    assert Material.notion_subject_label("english") == "English"
    assert Material.subject_from_label("Englisch") == "english"
    assert Material.subject_from_label("English") == "english"
  end
end

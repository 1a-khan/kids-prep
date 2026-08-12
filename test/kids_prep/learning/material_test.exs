defmodule KidsPrep.Learning.MaterialTest do
  use ExUnit.Case, async: true

  alias KidsPrep.Learning.Question
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

  test "english subject keeps questions and answers in English with German explanations" do
    questions = Material.daily_questions("mustafa", "english", ~D[2026-08-12])

    vocabulary = Enum.find(questions, &(&1.skill == "Vocabulary"))
    reading = Enum.find(questions, &(&1.skill == "Reading"))

    assert vocabulary.prompt =~ "What does"
    assert "a kind of food" in vocabulary.choices
    assert vocabulary.explanation =~ "Deutsch:"
    refute vocabulary.explanation =~ "Türkçe:"

    assert reading.prompt =~ "What"
    assert reading.explanation =~ "Deutsch:"
    refute reading.explanation =~ "Türkçe:"
  end

  test "german and maths subjects keep questions and explanations in German" do
    german = Material.daily_questions("mihrimah", "german", ~D[2026-08-12])
    maths = Material.daily_questions("mihrimah", "maths", ~D[2026-08-12])

    assert Enum.all?(german, &Material.valid_question_for_subject?("german", &1))
    assert Enum.all?(maths, &Material.valid_question_for_subject?("maths", &1))

    refute Enum.any?(german ++ maths, &String.contains?(&1.explanation, "The answer is"))
    refute Enum.any?(german ++ maths, &String.contains?(&1.prompt, "Choose the"))
  end

  test "language validation rejects wrong Notion material" do
    english_with_german_prompt = %Question{
      id: "bad-english",
      subject: "english",
      skill: "Vocabulary",
      level: 1,
      prompt: "Was bedeutet das englische Wort 'library'?",
      choices: ["ein Ort mit Büchern", "Essen"],
      answer: "ein Ort mit Büchern",
      explanation: "Deutsch: Erklärung."
    }

    maths_with_english_explanation = %Question{
      id: "bad-maths",
      subject: "maths",
      skill: "Plusrechnen",
      level: 1,
      prompt: "7 + 5 = ?",
      choices: [12, 13],
      answer: 12,
      explanation: "Add tens first, then ones."
    }

    assert not Material.valid_question_for_subject?("english", english_with_german_prompt)
    assert not Material.valid_question_for_subject?("maths", maths_with_english_explanation)
  end

  test "language validation rejects German subject with English answers" do
    german_with_english_answer = %Question{
      id: "bad-german-answer",
      subject: "german",
      skill: "Artikel",
      level: 1,
      prompt: "Welcher Artikel passt zu 'Lampe'?",
      choices: ["the", "a", "an"],
      answer: "the",
      explanation: "Jedes deutsche Nomen hat einen Artikel."
    }

    assert not Material.valid_question_for_subject?("german", german_with_english_answer)
  end

  test "language validation rejects English subject with German answers" do
    english_with_german_answer = %Question{
      id: "bad-english-answer",
      subject: "english",
      skill: "Vocabulary",
      level: 1,
      prompt: "What does 'dog' mean?",
      choices: ["ein Hund", "a place with books", "a number sentence"],
      answer: "ein Hund",
      explanation: "Deutsch: Die Antwort steht im englischen Wort."
    }

    assert not Material.valid_question_for_subject?("english", english_with_german_answer)
  end

  test "display labels are German while Notion labels remain compatible with existing databases" do
    assert Material.subject_label("english") == "Englisch"
    assert Material.notion_subject_label("english") == "English"
    assert Material.subject_from_label("Englisch") == "english"
    assert Material.subject_from_label("English") == "english"
  end
end

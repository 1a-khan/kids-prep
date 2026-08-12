defmodule KidsPrep.Learning.CacheTest do
  use KidsPrep.DataCase

  alias KidsPrep.Learning
  alias KidsPrep.Learning.DailyQuestionCache
  alias KidsPrep.Repo

  test "daily questions use valid SQLite cache before generated material" do
    date = ~D[2026-08-12]

    cached_question = %{
      "id" => "cached-german-1",
      "subject" => "german",
      "skill" => "Artikel",
      "level" => 1,
      "prompt" => "Welcher Artikel passt zu 'Schule'?",
      "choices" => ["der", "die", "das"],
      "answer" => "die",
      "explanation" => "Schule hat den Artikel die. Merke dir: die Schule."
    }

    insert_cache("mihrimah", "german", date, [cached_question])

    assert [%{id: "cached-german-1"}] = Learning.daily_questions("mihrimah", "german", date)
  end

  test "daily questions ignore invalid cached language material" do
    date = ~D[2026-08-12]

    invalid_question = %{
      "id" => "invalid-maths-1",
      "subject" => "maths",
      "skill" => "Subtraction",
      "level" => 1,
      "prompt" => "How many apples are left?",
      "choices" => [2, 3, 4],
      "answer" => 3,
      "explanation" => "Look at the number sentence and subtract."
    }

    insert_cache("mihrimah", "maths", date, [invalid_question])

    refute [%{id: "invalid-maths-1"}] == Learning.daily_questions("mihrimah", "maths", date)
  end

  defp insert_cache(child_slug, subject, date, questions) do
    %DailyQuestionCache{}
    |> DailyQuestionCache.changeset(%{
      child_slug: child_slug,
      subject: subject,
      quiz_date: date,
      questions: %{items: questions},
      source: "test",
      synced_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert!()
  end
end

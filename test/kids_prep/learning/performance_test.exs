defmodule KidsPrep.Learning.PerformanceTest do
  use KidsPrep.DataCase

  alias KidsPrep.Learning
  alias KidsPrep.Learning.Result
  alias KidsPrep.Repo

  test "adaptive level moves up after strong recent subject results" do
    insert_result("mihrimah", "Mihrimah", "german", ~D[2026-08-10], 18, 20)
    insert_result("mihrimah", "Mihrimah", "german", ~D[2026-08-11], 19, 20)

    assert Learning.adaptive_level("mihrimah", "german") == 2
  end

  test "performance dashboard summarizes children, subjects, and weak skills" do
    insert_result("mustafa", "Mustafa", "maths", ~D[2026-08-10], 8, 10, [
      %{"skill" => "Einmaleins"},
      %{"skill" => "Einmaleins"}
    ])

    dashboard = Learning.performance_dashboard()
    mustafa = Enum.find(dashboard.children, &(&1.slug == "mustafa"))
    maths = Enum.find(mustafa.subjects, &(&1.subject == "maths"))

    assert mustafa.average == 80
    assert maths.latest == 80
    assert [%{child: "Mustafa", skill: "Einmaleins", count: 2}] = dashboard.weak_skills
  end

  defp insert_result(child_slug, child_name, subject, date, score, total, wrong_items \\ []) do
    %Result{}
    |> Result.changeset(%{
      child_slug: child_slug,
      child_name: child_name,
      subject: subject,
      quiz_date: date,
      score: score,
      total: total,
      duration_seconds: 120,
      wrong_questions: %{"items" => wrong_items},
      answers: %{"items" => []}
    })
    |> Repo.insert!()
  end
end

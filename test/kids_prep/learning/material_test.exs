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
end

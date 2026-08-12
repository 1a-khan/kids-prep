defmodule KidsPrep.Learning.Question do
  @enforce_keys [:id, :subject, :prompt, :choices, :answer, :explanation]
  defstruct [:id, :subject, :prompt, :choices, :answer, :explanation, :skill, :level]
end

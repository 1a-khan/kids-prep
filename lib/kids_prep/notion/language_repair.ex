defmodule KidsPrep.Notion.LanguageRepair do
  @moduledoc false

  alias KidsPrep.Learning
  alias KidsPrep.Notion.{Client, Properties}

  @page_size 100

  def repair_german_material do
    with true <- Client.enabled?(),
         {:ok, pages} <- fetch_pages() do
      pages
      |> Enum.map(&repair_page/1)
      |> Enum.reject(&(&1 == :unchanged))
    else
      false -> {:error, :notion_disabled}
      error -> error
    end
  end

  def repaired_properties(%{
        "Subject" => subject,
        "Skill" => skill,
        "Prompt" => prompt,
        "Correct Answer" => answer,
        "Name" => name
      }) do
    case {subject, skill} do
      {"German", _} ->
        german_properties(name, skill, prompt, answer)

      {"Maths", _} ->
        maths_properties(name, skill, prompt, answer)

      _ ->
        %{}
    end
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp fetch_pages(cursor \\ nil, acc \\ []) do
    body =
      %{
        filter: %{
          and: [
            %{property: "Active", checkbox: %{equals: true}},
            %{
              or: [
                %{property: "Subject", select: %{equals: "German"}},
                %{property: "Subject", select: %{equals: "Maths"}}
              ]
            }
          ]
        },
        page_size: @page_size
      }
      |> maybe_put_cursor(cursor)

    case Client.query_database(Client.database_id(:questions_database_id), body) do
      {:ok, %{"results" => results, "has_more" => true, "next_cursor" => next_cursor}} ->
        fetch_pages(next_cursor, acc ++ results)

      {:ok, %{"results" => results}} ->
        {:ok, acc ++ results}

      error ->
        error
    end
  end

  defp repair_page(%{"id" => page_id, "properties" => notion_properties}) do
    current = plain_properties(notion_properties)
    properties = repaired_properties(current)

    if properties == %{} do
      :unchanged
    else
      Client.update_page(page_id, properties)
    end
  end

  defp plain_properties(properties) do
    %{
      "Subject" => properties |> Map.fetch!("Subject") |> Properties.select_name(),
      "Skill" => properties |> Map.fetch!("Skill") |> Properties.plain_text(),
      "Prompt" => properties |> Map.fetch!("Prompt") |> Properties.plain_text(),
      "Correct Answer" => properties |> Map.fetch!("Correct Answer") |> Properties.plain_text(),
      "Name" => properties |> Map.fetch!("Name") |> Properties.title_text()
    }
  end

  defp german_properties(name, skill, prompt, answer) do
    repaired_skill = german_skill(skill)
    repaired_prompt = german_prompt(skill, prompt)

    %{
      "Name" => Properties.title(repaired_name(name, "Deutsch", repaired_skill)),
      "Skill" => Properties.text(repaired_skill),
      "Prompt" => Properties.text(repaired_prompt),
      "Explanation" => Properties.text(german_explanation(skill, repaired_prompt, answer))
    }
  end

  defp maths_properties(name, skill, prompt, answer) do
    repaired_skill = maths_skill(skill)
    repaired_prompt = maths_prompt(skill, prompt)

    %{
      "Name" => Properties.title(repaired_name(name, "Mathe", repaired_skill)),
      "Skill" => Properties.text(repaired_skill),
      "Prompt" => Properties.text(repaired_prompt),
      "Explanation" => Properties.text(maths_explanation(skill, repaired_prompt, answer))
    }
  end

  defp german_prompt("Artikel", prompt) do
    case Regex.run(~r/'([^']+)'/, prompt) do
      [_, noun] -> "Welcher Artikel passt zu '#{noun}'?"
      _ -> prompt
    end
  end

  defp german_prompt("Verb endings", prompt) do
    String.replace(prompt, "Choose the correct verb:", "Wähle das richtige Verb:")
  end

  defp german_prompt("Word order", _prompt), do: "Baue den besten deutschen Satz."
  defp german_prompt(_skill, prompt), do: prompt

  defp german_explanation("Artikel", prompt, answer) do
    noun =
      case Regex.run(~r/'([^']+)'/, prompt) do
        [_, noun] -> noun
        _ -> ""
      end

    "Jedes deutsche Nomen hat einen Artikel. Sprich es als kleines Paket: '#{answer} #{noun}'."
  end

  defp german_explanation("Verbendungen", prompt, answer),
    do: german_explanation("Verb endings", prompt, answer)

  defp german_explanation("Verb endings", prompt, answer) do
    person =
      case Regex.run(~r/: ([^ ]+) ___/, prompt) do
        [_, person] -> person
        _ -> "die Person"
      end

    "Schau zuerst auf die Person. Zu '#{person}' passt '#{answer}', deshalb ändert sich die Endung."
  end

  defp german_explanation("Satzbau", prompt, answer),
    do: german_explanation("Word order", prompt, answer)

  defp german_explanation("Word order", _prompt, _answer),
    do: "In einem einfachen deutschen Hauptsatz steht das Verb meistens an zweiter Stelle."

  defp german_explanation(_skill, _prompt, _answer),
    do: "Lies die Frage noch einmal ruhig und achte auf die deutschen Wörter."

  defp maths_prompt("Word problem", prompt) do
    case Regex.run(~r/There are (\d+) apples\. The family eats (\d+)\./, prompt) do
      [_, apples, eaten] ->
        "Es gibt #{apples} Äpfel. Die Familie isst #{eaten}. Wie viele bleiben übrig?"

      _ ->
        prompt
    end
  end

  defp maths_prompt(_skill, prompt), do: prompt

  defp maths_explanation("Addition", prompt, _answer) do
    case numbers(prompt) do
      [a, b | _] ->
        "Rechne zuerst die Zehner, dann die Einer. Du kannst auch von #{a} aus #{b} Schritte weiterzählen."

      _ ->
        "Rechne zuerst die Zehner, dann die Einer."
    end
  end

  defp maths_explanation("Plusrechnen", prompt, answer),
    do: maths_explanation("Addition", prompt, answer)

  defp maths_explanation("Subtraction", _prompt, _answer),
    do:
      "Zerlege die kleinere Zahl in Zehner und Einer. Dann zählst du in zwei ruhigen Schritten zurück."

  defp maths_explanation("Subtraktion", prompt, answer),
    do: maths_explanation("Subtraction", prompt, answer)

  defp maths_explanation("Times tables", prompt, _answer) do
    case numbers(prompt) do
      [a, b | _] ->
        "Malnehmen bedeutet gleich große Gruppen: #{a} Gruppen mit je #{b}. Zähle in Sprüngen nach."

      _ ->
        "Malnehmen bedeutet gleich große Gruppen. Zähle in Sprüngen nach."
    end
  end

  defp maths_explanation("Einmaleins", prompt, answer),
    do: maths_explanation("Times tables", prompt, answer)

  defp maths_explanation("Word problem", prompt, _answer) do
    case numbers(prompt) do
      [apples, eaten | _] ->
        "'Übrig bleiben' bedeutet: minus rechnen. Starte mit #{apples} und nimm #{eaten} weg."

      _ ->
        "'Übrig bleiben' bedeutet: minus rechnen."
    end
  end

  defp maths_explanation("Textaufgabe", prompt, answer),
    do: maths_explanation("Word problem", prompt, answer)

  defp maths_explanation(_skill, _prompt, _answer), do: "Rechne Schritt für Schritt."

  defp repaired_name(name, subject, skill) do
    child =
      Learning.children()
      |> Enum.find_value(fn {_slug, child} ->
        if String.contains?(name, child.name), do: child.name
      end) || "Both"

    "#{child} #{subject} #{skill}"
  end

  defp german_skill("Verb endings"), do: "Verbendungen"
  defp german_skill("Word order"), do: "Satzbau"
  defp german_skill(skill), do: skill

  defp maths_skill("Addition"), do: "Plusrechnen"
  defp maths_skill("Subtraction"), do: "Subtraktion"
  defp maths_skill("Times tables"), do: "Einmaleins"
  defp maths_skill("Word problem"), do: "Textaufgabe"
  defp maths_skill(skill), do: skill

  defp numbers(text) do
    ~r/\d+/
    |> Regex.scan(text)
    |> List.flatten()
  end

  defp maybe_put_cursor(body, nil), do: body
  defp maybe_put_cursor(body, cursor), do: Map.put(body, :start_cursor, cursor)
end

defmodule KidsPrep.Learning.Material do
  alias KidsPrep.Learning.Question

  @children %{
    "mihrimah" => %{
      name: "Mihrimah",
      age: 8,
      completed_class: "2. Klasse in der Türkei abgeschlossen",
      target: "Vorbereitung auf Klasse 3"
    },
    "mustafa" => %{
      name: "Mustafa",
      age: 10,
      completed_class: "4. Klasse in der Türkei abgeschlossen",
      target: "Vorbereitung auf Klasse 5"
    }
  }

  @subjects ~w(german english maths)

  def children, do: @children
  def subjects, do: @subjects

  def subject_label("german"), do: "Deutsch"
  def subject_label("english"), do: "Englisch"
  def subject_label("maths"), do: "Mathe"

  def notion_subject_label("german"), do: "German"
  def notion_subject_label("english"), do: "English"
  def notion_subject_label("maths"), do: "Maths"

  def subject_from_label(label) do
    case String.downcase(to_string(label)) do
      "german" -> "german"
      "deutsch" -> "german"
      "english" -> "english"
      "englisch" -> "english"
      "maths" -> "maths"
      "math" -> "maths"
      "mathe" -> "maths"
      other -> other
    end
  end

  def child!(slug), do: Map.fetch!(@children, slug)

  def valid_questions_for_subject?(subject, questions) when is_list(questions) do
    questions != [] and Enum.all?(questions, &valid_question_for_subject?(subject, &1))
  end

  def valid_question_for_subject?("english", question) do
    english_text?(question.prompt) and Enum.all?(question.choices, &english_text?/1) and
      english_text?(question.answer) and german_explanation?(question.explanation)
  end

  def valid_question_for_subject?(_subject, question) do
    german_learning_text?(question.prompt) and german_learning_text?(question.explanation)
  end

  def daily_questions(child_slug, subject, date \\ Date.utc_today()) do
    seed = :erlang.phash2({child_slug, subject, date})
    level = if child_slug == "mustafa", do: 2, else: 1

    subject
    |> build_subject(level, seed)
    |> Enum.with_index(1)
    |> Enum.map(fn {question, index} ->
      %{question | id: "#{date}-#{child_slug}-#{subject}-#{index}"}
    end)
  end

  defp build_subject("german", level, seed) do
    nouns = [
      {"Hund", "der"},
      {"Blume", "die"},
      {"Haus", "das"},
      {"Apfel", "der"},
      {"Schule", "die"},
      {"Buch", "das"},
      {"Tisch", "der"},
      {"Lampe", "die"},
      {"Fenster", "das"},
      {"Lehrer", "der"},
      {"Tasche", "die"},
      {"Kind", "das"}
    ]

    verbs = [
      {"ich", "gehe", "gehen"},
      {"du", "spielst", "spielen"},
      {"er", "liest", "lesen"},
      {"wir", "lernen", "lernen"},
      {"sie", "schreibt", "schreiben"},
      {"ihr", "macht", "machen"},
      {"ich", "bin", "sein"},
      {"du", "hast", "haben"},
      {"wir", "kommen", "kommen"},
      {"sie", "trinkt", "trinken"}
    ]

    sentence_words = [
      {"Morgen", "gehen", "wir", "zur Schule"},
      {"Heute", "liest", "Mustafa", "ein Buch"},
      {"Mihrimah", "malt", "eine", "Blume"},
      {"Im Sommer", "spielen", "die Kinder", "draußen"},
      {"Nachmittags", "macht", "Mustafa", "Hausaufgaben"},
      {"Am Abend", "lernt", "Mihrimah", "Deutsch"}
    ]

    article_questions =
      nouns
      |> rotate(seed)
      |> Enum.take(10)
      |> Enum.map(fn {noun, article} ->
        q(
          "german",
          "Artikel",
          level,
          "Welcher Artikel passt zu '#{noun}'?",
          ["der", "die", "das"],
          article,
          "Jedes deutsche Nomen hat einen Artikel. Sprich es als kleines Paket: '#{article} #{noun}'."
        )
      end)

    verb_questions =
      verbs
      |> rotate(seed + 4)
      |> Enum.take(8)
      |> Enum.map(fn {person, form, infinitive} ->
        q(
          "german",
          "Verbendungen",
          level,
          "Wähle das richtige Verb: #{person} ___ (#{infinitive})",
          distract_verbs(form),
          form,
          "Schau zuerst auf die Person. Zu '#{person}' passt '#{form}', deshalb ändert sich die Endung."
        )
      end)

    word_order_questions =
      sentence_words
      |> rotate(seed + 8)
      |> Enum.take(if(level == 2, do: 7, else: 4))
      |> Enum.map(fn parts ->
        answer = Tuple.to_list(parts) |> Enum.join(" ")

        choices = [
          answer,
          Enum.join(Enum.reverse(Tuple.to_list(parts)), " "),
          Enum.join(tl(Tuple.to_list(parts)) ++ [elem(parts, 0)], " ")
        ]

        q(
          "german",
          "Satzbau",
          level,
          "Baue den besten deutschen Satz.",
          choices,
          answer,
          "In einem einfachen deutschen Hauptsatz steht das Verb meistens an zweiter Stelle."
        )
      end)

    article_questions ++ verb_questions ++ word_order_questions
  end

  defp build_subject("english", level, seed) do
    vocab = [
      {"library", "a place with books", "Bibliothek"},
      {"bridge", "something you cross", "Brücke"},
      {"quickly", "in a fast way", "schnell"},
      {"friendly", "kind and nice", "freundlich"},
      {"journey", "a trip", "Reise"},
      {"answer", "a reply", "Antwort"},
      {"before", "earlier than", "vorher"},
      {"because", "for the reason that", "weil"},
      {"between", "in the middle of two things", "zwischen"},
      {"careful", "doing something with attention", "vorsichtig"},
      {"mistake", "something to learn from", "Fehler"},
      {"practice", "repeating to get better", "Übung"}
    ]

    grammar = [
      {"She ___ to school every day.", "goes", ["go", "goes", "going"]},
      {"They ___ football after lunch.", "play", ["plays", "play", "playing"]},
      {"I have ___ apple.", "an", ["a", "an", "the"]},
      {"Mustafa is taller ___ Mihrimah.", "than", ["then", "than", "that"]},
      {"Yesterday we ___ a story.", "read", ["read", "reads", "reading"]},
      {"Mihrimah ___ happy today.", "is", ["are", "is", "am"]},
      {"We ___ in Germany now.", "live", ["lives", "live", "living"]},
      {"The book is ___ the table.", "on", ["on", "understand", "quickly"]},
      {"Mustafa can ___ three languages.", "speak", ["speaks", "speak", "speaking"]},
      {"The children ___ ready for school.", "are", ["is", "are", "am"]}
    ]

    reading = [
      {"Lena packed her bag before breakfast because the bus arrived early.",
       "Why did Lena pack before breakfast?", "because the bus arrived early"},
      {"The children shared pencils when one box was empty.", "What did the children share?",
       "pencils"},
      {"A small map helped the family find the new school.", "What helped the family?",
       "a small map"},
      {"After the lesson, Mustafa checked his answer and fixed one mistake.",
       "What did Mustafa fix?", "one mistake"},
      {"Mihrimah read the question twice before choosing.", "What did Mihrimah read twice?",
       "the question"}
    ]

    vocab_questions =
      vocab
      |> rotate(seed)
      |> Enum.take(10)
      |> Enum.map(fn {word, meaning, explanation_hint} ->
        choices =
          [meaning, "a kind of food", "a number sentence"]
          |> rotate(seed + byte_size(word))

        q(
          "english",
          "Vocabulary",
          level,
          "What does '#{word}' mean?",
          choices,
          meaning,
          "Deutsch: '#{word}' bedeutet #{explanation_hint}. Lies das ganze Wort und stelle dir ein Bild dazu vor."
        )
      end)

    grammar_questions =
      grammar
      |> rotate(seed + 5)
      |> Enum.take(10)
      |> Enum.map(fn {prompt, answer, choices} ->
        q(
          "english",
          "Grammar",
          level,
          prompt,
          choices,
          answer,
          "Deutsch: Schau auf die Person und auf die Zeit im Satz. Kleine Wörter und Endungen zeigen die Grammatik."
        )
      end)

    reading_questions =
      reading
      |> rotate(seed + 9)
      |> Enum.take(if(level == 2, do: 5, else: 3))
      |> Enum.map(fn {text, prompt, answer} ->
        q(
          "english",
          "Reading",
          level,
          "#{text}\n\n#{prompt}",
          [answer, "breakfast", "the new teacher"],
          answer,
          "Deutsch: Die Antwort steht im englischen Text. Lies den Satz noch einmal und suche die Wörter, die es beweisen."
        )
      end)

    vocab_questions ++ grammar_questions ++ reading_questions
  end

  defp build_subject("maths", level, seed) do
    limit = if level == 2, do: 120, else: 60

    arithmetic =
      for n <- 1..14 do
        a = rem(seed + n * 7, limit) + 5
        b = rem(seed + n * 11, div(limit, 2)) + 3
        answer = a + b

        q(
          "maths",
          "Plusrechnen",
          level,
          "#{a} + #{b} = ?",
          number_choices(answer, seed + n),
          answer,
          "Rechne zuerst die Zehner, dann die Einer. Du kannst auch von #{a} aus #{b} Schritte weiterzählen."
        )
      end

    subtraction =
      for n <- 1..8 do
        a = rem(seed + n * 13, limit) + 30
        b = rem(seed + n * 5, 25) + 2
        answer = a - b

        q(
          "maths",
          "Subtraktion",
          level,
          "#{a} - #{b} = ?",
          number_choices(answer, seed + n * 2),
          answer,
          "Zerlege die kleinere Zahl in Zehner und Einer. Dann zählst du in zwei ruhigen Schritten zurück."
        )
      end

    multiplication =
      for n <- 1..if(level == 2, do: 8, else: 4) do
        a = rem(seed + n, 9) + 2
        b = rem(seed + n * 3, 9) + 2
        answer = a * b

        q(
          "maths",
          "Einmaleins",
          level,
          "#{a} x #{b} = ?",
          number_choices(answer, seed + n * 3),
          answer,
          "Malnehmen bedeutet gleich große Gruppen: #{a} Gruppen mit je #{b}. Zähle in Sprüngen nach."
        )
      end

    word =
      for n <- 1..if(level == 2, do: 5, else: 3) do
        apples = rem(seed + n * 4, 20) + 8
        eaten = rem(seed + n * 6, 7) + 2
        answer = apples - eaten

        q(
          "maths",
          "Textaufgabe",
          level,
          "Es gibt #{apples} Äpfel. Die Familie isst #{eaten}. Wie viele bleiben übrig?",
          number_choices(answer, seed + n * 4),
          answer,
          "'Übrig bleiben' bedeutet: minus rechnen. Starte mit #{apples} und nimm #{eaten} weg."
        )
      end

    arithmetic ++ subtraction ++ multiplication ++ word
  end

  defp q(subject, skill, level, prompt, choices, answer, explanation) do
    %Question{
      id: "pending",
      subject: subject,
      skill: skill,
      level: level,
      prompt: prompt,
      choices: Enum.uniq(choices),
      answer: answer,
      explanation: explanation
    }
  end

  defp number_choices(answer, seed) do
    [answer, answer + rem(seed, 4) + 1, max(answer - rem(seed, 5) - 1, 0)]
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp distract_verbs(form) do
    ([form, form <> "e", String.trim_trailing(form, "st")] ++ ["gehen", "macht"])
    |> Enum.uniq()
    |> Enum.take(3)
  end

  defp rotate(list, seed) do
    {left, right} = Enum.split(list, rem(seed, length(list)))
    right ++ left
  end

  defp english_text?(value) do
    text = to_string(value)

    String.match?(text, ~r/[A-Za-z]/) and not turkish_text?(text) and
      not german_instruction?(text)
  end

  defp german_explanation?(value) do
    text = to_string(value)
    german_learning_text?(text) and not turkish_text?(text)
  end

  defp german_learning_text?(value) do
    text = to_string(value)
    not english_instruction?(text) and not turkish_text?(text)
  end

  defp english_instruction?(value) do
    value
    |> to_string()
    |> String.downcase()
    |> then(&String.contains?(&1, english_instruction_markers()))
  end

  defp german_instruction?(value) do
    value
    |> to_string()
    |> String.downcase()
    |> then(&String.contains?(&1, german_instruction_markers()))
  end

  defp turkish_text?(value) do
    String.contains?(to_string(value), ["Türkçe:", "ı", "İ", "ğ", "Ğ", "ş", "Ş"])
  end

  defp english_instruction_markers do
    [
      "which article",
      "choose the",
      "build the",
      "what does",
      "why did",
      "what did",
      "what helped",
      "the answer is",
      "go back",
      "look at",
      "check the",
      "add tens",
      "break the",
      "multiplication is",
      "there are",
      "how many",
      "left means"
    ]
  end

  defp german_instruction_markers do
    [
      "welcher",
      "wähle",
      "baue",
      "was bedeutet",
      "warum",
      "was teilten",
      "was half",
      "schau",
      "lies",
      "deutsch:",
      "türkçe:"
    ]
  end
end

defmodule KidsPrep.Learning.Material do
  alias KidsPrep.Learning.Question

  @children %{
    "mihrimah" => %{
      name: "Mihrimah",
      age: 8,
      completed_class: "Class 2 in Turkiye",
      target: "Gymnasium bridge: Klasse 3"
    },
    "mustafa" => %{
      name: "Mustafa",
      age: 10,
      completed_class: "Class 4 in Turkiye",
      target: "Gymnasium bridge: Klasse 5"
    }
  }

  @subjects ~w(german english maths)

  def children, do: @children
  def subjects, do: @subjects

  def subject_label("german"), do: "German"
  def subject_label("english"), do: "English"
  def subject_label("maths"), do: "Maths"

  def child!(slug), do: Map.fetch!(@children, slug)

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
          "Which article belongs to '#{noun}'?",
          ["der", "die", "das"],
          article,
          "In German every noun has a gender. Say it as one chunk: '#{article} #{noun}'."
        )
      end)

    verb_questions =
      verbs
      |> rotate(seed + 4)
      |> Enum.take(8)
      |> Enum.map(fn {person, form, infinitive} ->
        q(
          "german",
          "Verb endings",
          level,
          "Choose the correct verb: #{person} ___ (#{infinitive})",
          distract_verbs(form),
          form,
          "Look at the person first. '#{person}' needs '#{form}', so the ending changes."
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
          "Word order",
          level,
          "Build the best German sentence.",
          choices,
          answer,
          "German sentences usually keep the verb in the second position in simple main clauses."
        )
      end)

    article_questions ++ verb_questions ++ word_order_questions
  end

  defp build_subject("english", level, seed) do
    vocab = [
      {"library", "a place with books"},
      {"bridge", "something you cross"},
      {"quickly", "in a fast way"},
      {"friendly", "kind and nice"},
      {"journey", "a trip"},
      {"answer", "a reply"},
      {"before", "earlier than"},
      {"because", "for the reason that"},
      {"between", "in the middle of two things"},
      {"careful", "doing something with attention"},
      {"mistake", "something to learn from"},
      {"practice", "repeating to get better"}
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
      |> Enum.map(fn {word, meaning} ->
        choices =
          [meaning, "a kind of food", "a number sentence"] |> rotate(seed + byte_size(word))

        q(
          "english",
          "Vocabulary",
          level,
          "What does '#{word}' mean?",
          choices,
          meaning,
          "Read the whole word and connect it to a picture in your head. '#{word}' means #{meaning}."
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
          "Check the subject and the time word. Tiny words and endings carry the grammar."
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
          "The answer is inside the text. Go back and underline the words that prove it."
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
          "Addition",
          level,
          "#{a} + #{b} = ?",
          number_choices(answer, seed + n),
          answer,
          "Add tens first, then ones. You can also jump forward by #{b} from #{a}."
        )
      end

    subtraction =
      for n <- 1..8 do
        a = rem(seed + n * 13, limit) + 30
        b = rem(seed + n * 5, 25) + 2
        answer = a - b

        q(
          "maths",
          "Subtraction",
          level,
          "#{a} - #{b} = ?",
          number_choices(answer, seed + n * 2),
          answer,
          "Break the smaller number into tens and ones, then count back in two calm steps."
        )
      end

    multiplication =
      for n <- 1..if(level == 2, do: 8, else: 4) do
        a = rem(seed + n, 9) + 2
        b = rem(seed + n * 3, 9) + 2
        answer = a * b

        q(
          "maths",
          "Times tables",
          level,
          "#{a} x #{b} = ?",
          number_choices(answer, seed + n * 3),
          answer,
          "Multiplication is equal groups: #{a} groups of #{b}. Skip-count to check your answer."
        )
      end

    word =
      for n <- 1..if(level == 2, do: 5, else: 3) do
        apples = rem(seed + n * 4, 20) + 8
        eaten = rem(seed + n * 6, 7) + 2
        answer = apples - eaten

        q(
          "maths",
          "Word problem",
          level,
          "There are #{apples} apples. The family eats #{eaten}. How many are left?",
          number_choices(answer, seed + n * 4),
          answer,
          "'Left' means subtract. Start with #{apples}, take away #{eaten}."
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
end

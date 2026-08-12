defmodule KidsPrepWeb.QuizLive do
  use KidsPrepWeb, :live_view

  alias KidsPrep.Accounts
  alias KidsPrep.Learning

  @impl true
  def mount(_params, %{"current_user" => current_user}, socket) do
    child_slug = current_user["child_slug"]
    children = visible_children(current_user)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:children, children)
      |> assign(:subjects, Learning.subjects())
      |> assign(:recent_results, recent_results(current_user))
      |> assign(:child_slug, child_slug)
      |> assign(:subject, nil)
      |> assign(:questions, [])
      |> assign(:index, 0)
      |> assign(:selected, nil)
      |> assign(:feedback, nil)
      |> assign(:answers, [])
      |> assign(:wrong, [])
      |> assign(:mode, initial_mode(current_user))
      |> assign(:started_at, nil)
      |> assign(:saved_result, nil)

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/login")}
  end

  @impl true
  def handle_event("choose_child", %{"id" => child_slug}, socket) do
    if Accounts.allowed_child?(socket.assigns.current_user, child_slug) do
      {:noreply, assign(socket, child_slug: child_slug, mode: :subject)}
    else
      {:noreply, put_flash(socket, :error, "This learner is not available for your account.")}
    end
  end

  def handle_event(
        "choose_subject",
        %{"id" => subject},
        %{assigns: %{child_slug: child_slug}} = socket
      ) do
    questions = Learning.daily_questions(child_slug, subject)

    {:noreply,
     socket
     |> assign(:subject, subject)
     |> assign(:questions, questions)
     |> assign(:index, 0)
     |> assign(:selected, nil)
     |> assign(:feedback, nil)
     |> assign(:answers, [])
     |> assign(:wrong, [])
     |> assign(:mode, :quiz)
     |> assign(:started_at, DateTime.utc_now())
     |> assign(:saved_result, nil)}
  end

  def handle_event("answer", %{"choice" => choice}, socket) do
    question = current_question(socket)
    correct? = to_string(question.answer) == choice

    feedback = %{
      correct?: correct?,
      title: if(correct?, do: "Correct. Nice thinking.", else: "Not quite yet."),
      body: if(correct?, do: "Keep going while your brain is warm.", else: question.explanation)
    }

    answer = %{
      id: question.id,
      skill: question.skill,
      prompt: question.prompt,
      selected: choice,
      answer: question.answer,
      correct?: correct?,
      explanation: question.explanation
    }

    wrong = if correct?, do: socket.assigns.wrong, else: [question | socket.assigns.wrong]

    {:noreply,
     socket
     |> assign(:selected, choice)
     |> assign(:feedback, feedback)
     |> assign(:answers, socket.assigns.answers ++ [answer])
     |> assign(:wrong, wrong)}
  end

  def handle_event("next", _params, socket) do
    next_index = socket.assigns.index + 1

    if next_index >= length(socket.assigns.questions) do
      {:noreply, finish_quiz(socket)}
    else
      {:noreply, assign(socket, index: next_index, selected: nil, feedback: nil)}
    end
  end

  def handle_event("retry_wrong", _params, socket) do
    questions =
      socket.assigns.wrong
      |> Enum.reverse()
      |> Enum.with_index(1)
      |> Enum.map(fn {question, index} -> %{question | id: "retry-#{question.id}-#{index}"} end)

    {:noreply,
     socket
     |> assign(:questions, questions)
     |> assign(:index, 0)
     |> assign(:selected, nil)
     |> assign(:feedback, nil)
     |> assign(:answers, [])
     |> assign(:wrong, [])
     |> assign(:mode, :retry)
     |> assign(:started_at, DateTime.utc_now())}
  end

  def handle_event("home", _params, socket) do
    {:noreply,
     socket
     |> assign(:recent_results, recent_results(socket.assigns.current_user))
     |> assign(:mode, initial_mode(socket.assigns.current_user))
     |> assign(:child_slug, socket.assigns.current_user["child_slug"])
     |> assign(:subject, nil)
     |> assign(:questions, [])
     |> assign(:index, 0)
     |> assign(:selected, nil)
     |> assign(:feedback, nil)
     |> assign(:answers, [])
     |> assign(:wrong, [])}
  end

  defp finish_quiz(%{assigns: %{mode: :retry}} = socket), do: assign(socket, mode: :done)

  defp finish_quiz(socket) do
    child = Learning.child!(socket.assigns.child_slug)
    total = length(socket.assigns.questions)
    score = Enum.count(socket.assigns.answers, & &1.correct?)
    duration = DateTime.diff(DateTime.utc_now(), socket.assigns.started_at)

    attrs = %{
      child_slug: socket.assigns.child_slug,
      child_name: child.name,
      subject: socket.assigns.subject,
      quiz_date: Date.utc_today(),
      score: score,
      total: total,
      duration_seconds: duration,
      wrong_questions: %{items: Enum.map(Enum.reverse(socket.assigns.wrong), &question_to_map/1)},
      answers: %{items: socket.assigns.answers}
    }

    {:ok, result} = Learning.save_result(attrs)

    socket
    |> assign(:saved_result, result)
    |> assign(:recent_results, Learning.recent_results())
    |> assign(:mode, :done)
  end

  defp current_question(socket), do: Enum.at(socket.assigns.questions, socket.assigns.index)

  defp visible_children(%{"role" => "admin"}), do: Learning.children()

  defp visible_children(%{"child_slug" => child_slug}) do
    Map.take(Learning.children(), [child_slug])
  end

  defp initial_mode(%{"role" => "admin"}), do: :home
  defp initial_mode(_current_user), do: :subject

  defp recent_results(%{"role" => "admin"}), do: Learning.recent_results()

  defp recent_results(%{"child_slug" => child_slug}) do
    Learning.recent_results()
    |> Enum.filter(&(&1.child_slug == child_slug))
  end

  defp question_to_map(question) do
    %{
      id: question.id,
      subject: question.subject,
      skill: question.skill,
      level: question.level,
      prompt: question.prompt,
      choices: question.choices,
      answer: question.answer,
      explanation: question.explanation
    }
  end

  defp percent(score, total) when total > 0, do: round(score / total * 100)
  defp percent(_, _), do: 0
end

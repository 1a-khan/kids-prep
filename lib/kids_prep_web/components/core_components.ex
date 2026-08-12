defmodule KidsPrepWeb.CoreComponents do
  use Phoenix.Component

  attr :kind, :string, default: "button"
  attr :class, :string, default: ""

  attr :rest, :global,
    include: ~w(disabled form name value phx-click phx-value-id phx-value-choice phx-submit)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@kind} class={["btn", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end

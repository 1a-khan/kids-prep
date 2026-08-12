defmodule KidsPrep.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KidsPrep.Repo,
      {Phoenix.PubSub, name: KidsPrep.PubSub},
      KidsPrep.Notion.Scheduler,
      KidsPrepWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: KidsPrep.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    KidsPrepWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

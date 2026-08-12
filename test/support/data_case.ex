defmodule KidsPrep.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias KidsPrep.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import KidsPrep.DataCase
    end
  end

  setup tags do
    setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(KidsPrep.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end

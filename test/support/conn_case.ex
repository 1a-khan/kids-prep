defmodule KidsPrepWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint KidsPrepWeb.Endpoint

      use KidsPrepWeb, :verified_routes
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
    end
  end

  setup tags do
    KidsPrep.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

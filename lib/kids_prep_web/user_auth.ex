defmodule KidsPrepWeb.UserAuth do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn

  def fetch_current_user(conn, _opts) do
    assign(conn, :current_user, get_session(conn, :current_user))
  end

  def redirect_if_authenticated(%{assigns: %{current_user: current_user}} = conn, _opts)
      when not is_nil(current_user) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  def redirect_if_authenticated(conn, _opts), do: conn

  def require_authenticated_user(%{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> put_flash(:error, "Bitte melde dich zuerst an.")
    |> redirect(to: "/login")
    |> halt()
  end

  def require_authenticated_user(conn, _opts), do: conn
end

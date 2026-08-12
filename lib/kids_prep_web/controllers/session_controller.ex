defmodule KidsPrepWeb.SessionController do
  use KidsPrepWeb, :controller

  alias KidsPrep.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate(username, password) do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)
        |> put_session(:current_user, user)
        |> put_flash(:info, "Willkommen, #{user["display_name"]}.")
        |> redirect(to: ~p"/")

      :error ->
        conn
        |> put_flash(:error, "Benutzername oder Passwort ist nicht richtig.")
        |> render(:new)
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/login")
  end
end

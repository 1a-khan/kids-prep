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
        |> put_flash(:info, "Welcome, #{user["display_name"]}.")
        |> redirect(to: ~p"/")

      :error ->
        conn
        |> put_flash(:error, "Username or password is not correct.")
        |> render(:new)
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/login")
  end
end

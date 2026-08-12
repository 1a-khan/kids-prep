defmodule KidsPrepWeb.QuizLiveTest do
  use KidsPrepWeb.ConnCase

  setup do
    System.put_env("KIDS_PREP_MIHRIMAH_PASSWORD", "test-mihrimah-password")
    System.put_env("KIDS_PREP_MUSTAFA_PASSWORD", "test-mustafa-password")
    System.put_env("KIDS_PREP_ADMIN_PASSWORD", "test-admin-password")

    on_exit(fn ->
      System.delete_env("KIDS_PREP_MIHRIMAH_PASSWORD")
      System.delete_env("KIDS_PREP_MUSTAFA_PASSWORD")
      System.delete_env("KIDS_PREP_ADMIN_PASSWORD")
    end)
  end

  test "redirects guests to login", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/")
  end

  test "admin can choose a child and subject", %{conn: conn} do
    conn = log_in(conn, "admin", "test-admin-password")

    {:ok, view, _html} = live(conn, ~p"/")

    assert view |> element("button", "Mihrimah") |> render_click() =~ "Wähle ein Fach"
    assert view |> element("button", "Deutsch") |> render_click() =~ "Frage 1"
  end

  test "admin can request a SQLite question cache refresh", %{conn: conn} do
    conn = log_in(conn, "admin", "test-admin-password")

    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Fragen aktualisieren"
    assert view |> element("button", "Fragen aktualisieren") |> render_click() =~ "Module"
  end

  test "admin can open the in-app performance dashboard", %{conn: conn} do
    conn = log_in(conn, "admin", "test-admin-password")

    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Leistung"
    assert view |> element("button", "Leistung") |> render_click() =~ "SQLite-Auswertung"
  end

  test "learner logs in directly to their own subject picker", %{conn: conn} do
    conn = log_in(conn, "mustafa", "test-mustafa-password")

    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Mustafa"
    assert html =~ "Wähle ein Fach"
    refute html =~ "Notion verbinden"
    assert view |> element("button", "Mathe") |> render_click() =~ "Frage 1"
  end

  test "login rejects a bad password", %{conn: conn} do
    conn =
      post(conn, ~p"/login", %{
        "user" => %{"username" => "admin", "password" => "wrong"}
      })

    assert html_response(conn, 200) =~ "Benutzername oder Passwort ist nicht richtig."
  end

  defp log_in(conn, username, password) do
    conn =
      post(conn, ~p"/login", %{
        "user" => %{"username" => username, "password" => password}
      })

    assert redirected_to(conn) == ~p"/"
    conn
  end
end

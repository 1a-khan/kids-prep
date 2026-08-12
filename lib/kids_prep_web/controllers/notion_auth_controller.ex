defmodule KidsPrepWeb.NotionAuthController do
  use KidsPrepWeb, :controller

  alias KidsPrep.Notion.OAuth

  def start(conn, _params) do
    state = random_state()

    case OAuth.authorization_url(state) do
      {:ok, url} ->
        conn
        |> put_session(:notion_oauth_state, state)
        |> redirect(external: url)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Notion OAuth is not configured in OpenBao yet.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    with true <- secure_compare(state, get_session(conn, :notion_oauth_state)),
         {:ok, _token_response} <- OAuth.exchange_code(code, callback_url(conn)) do
      conn
      |> delete_session(:notion_oauth_state)
      |> put_flash(:info, "Notion connected. Daily modules can now sync through OpenBao.")
      |> redirect(to: ~p"/")
    else
      _ ->
        conn
        |> put_flash(
          :error,
          "Notion connection failed. Check OpenBao OAuth settings and redirect URI."
        )
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Notion did not return an authorization code.")
    |> redirect(to: ~p"/")
  end

  defp callback_url(conn) do
    scheme = Atom.to_string(conn.scheme)
    port = port_part(scheme, conn.port)
    "#{scheme}://#{conn.host}#{port}/auth/notion/callback"
  end

  defp port_part("http", 80), do: ""
  defp port_part("https", 443), do: ""
  defp port_part(_scheme, port), do: ":#{port}"

  defp random_state do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp secure_compare(left, right) when is_binary(left) and is_binary(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_compare(_, _), do: false
end

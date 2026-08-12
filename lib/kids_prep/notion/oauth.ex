defmodule KidsPrep.Notion.OAuth do
  @moduledoc false

  alias KidsPrep.Secrets.OpenBao

  @token_url "https://api.notion.com/v1/oauth/token"

  def configured? do
    case OpenBao.read_notion_oauth_config() do
      {:ok,
       %{
         "client_id" => client_id,
         "client_secret" => client_secret,
         "authorization_url" => auth_url
       }} ->
        Enum.all?([client_id, client_secret, auth_url], &present?/1)

      {:ok, %{"client_id" => client_id, "client_secret" => client_secret, "auth_url" => auth_url}} ->
        Enum.all?([client_id, client_secret, auth_url], &present?/1)

      _ ->
        false
    end
  end

  def authorization_url(state) do
    with {:ok, config} <- OpenBao.read_notion_oauth_config(),
         {:ok, auth_url} <- fetch_auth_url(config) do
      separator = if String.contains?(auth_url, "?"), do: "&", else: "?"
      {:ok, auth_url <> separator <> URI.encode_query(%{state: state})}
    end
  end

  def exchange_code(code, redirect_uri) do
    with {:ok, config} <- OpenBao.read_notion_oauth_config(),
         {:ok, client_id} <- fetch_present(config, "client_id"),
         {:ok, client_secret} <- fetch_present(config, "client_secret"),
         {:ok, body} <- request_token(client_id, client_secret, code, redirect_uri),
         :ok <- OpenBao.write_notion_oauth_tokens(body) do
      {:ok, body}
    end
  end

  defp request_token(client_id, client_secret, code, redirect_uri) do
    auth = Base.encode64("#{client_id}:#{client_secret}")

    Req.post(@token_url,
      headers: [
        {"authorization", "Basic #{auth}"},
        {"content-type", "application/json"}
      ],
      json: %{
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri
      }
    )
    |> case do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_auth_url(config), do: fetch_present(config, "authorization_url", "auth_url")

  defp fetch_present(config, primary, fallback \\ nil) do
    value = config[primary] || config[fallback]

    if present?(value) do
      {:ok, value}
    else
      {:error, {:missing_oauth_config, primary}}
    end
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end

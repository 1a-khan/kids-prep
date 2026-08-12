defmodule KidsPrep.Notion.Client do
  @moduledoc false

  @base_url "https://api.notion.com/v1"
  @version "2022-06-28"

  def enabled?, do: token() not in [nil, ""]

  def database_id(key), do: notion_config()[to_string(key)]

  def query_database(database_id, body \\ %{})
  def query_database(nil, _body), do: {:error, :missing_database_id}

  def query_database(database_id, body) do
    request(:post, "/databases/#{database_id}/query", json: body)
  end

  def create_page(nil, _properties), do: {:error, :missing_database_id}

  def create_page(database_id, properties) do
    request(:post, "/pages", json: %{parent: %{database_id: database_id}, properties: properties})
  end

  def update_page(page_id, properties) do
    request(:patch, "/pages/#{page_id}", json: %{properties: properties})
  end

  defp request(method, path, opts) do
    if enabled?() do
      headers = [
        {"authorization", "Bearer #{token()}"},
        {"notion-version", @version},
        {"content-type", "application/json"}
      ]

      safe_request(method, Keyword.merge(opts, url: @base_url <> path, headers: headers))
    else
      {:error, :notion_disabled}
    end
  end

  defp safe_request(method, opts) do
    opts
    |> Keyword.put(:method, method)
    |> Req.request()
    |> case do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    exception -> {:error, {exception.__struct__, Exception.message(exception)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp token do
    System.get_env("NOTION_TOKEN") || KidsPrep.Secrets.OpenBao.read_notion_token()
  end

  defp notion_config do
    app_config =
      :kids_prep
      |> Application.get_env(:notion, [])
      |> Map.new(fn {key, value} -> {to_string(key), value} end)

    case KidsPrep.Secrets.OpenBao.read_notion_config() do
      {:ok, openbao_config} when is_map(openbao_config) ->
        Map.merge(app_config, openbao_config)

      _ ->
        app_config
    end
  end
end

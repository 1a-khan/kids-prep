defmodule KidsPrep.Notion.Client do
  @moduledoc false

  @base_url "https://api.notion.com/v1"
  @version "2022-06-28"

  def enabled?, do: token() not in [nil, ""]

  def database_id(key), do: notion_config() |> Keyword.fetch!(key)

  def query_database(database_id, body \\ %{}) do
    request(:post, "/databases/#{database_id}/query", json: body)
  end

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

  defp notion_config, do: Application.fetch_env!(:kids_prep, :notion)
end

defmodule KidsPrep.Notion.Properties do
  @moduledoc false

  def title(value), do: %{title: [%{type: "text", text: %{content: to_string(value)}}]}
  def text(nil), do: %{rich_text: []}
  def text(value), do: %{rich_text: [%{type: "text", text: %{content: to_string(value)}}]}
  def select(value), do: %{select: %{name: to_string(value)}}
  def status(value), do: %{status: %{name: to_string(value)}}
  def number(value), do: %{number: value}
  def checkbox(value), do: %{checkbox: value}
  def date(%Date{} = date), do: %{date: %{start: Date.to_iso8601(date)}}
  def date(%DateTime{} = date), do: %{date: %{start: DateTime.to_iso8601(date)}}
  def date(nil), do: %{date: nil}

  def plain_text(property) when is_map(property) do
    property
    |> Map.get("rich_text", [])
    |> Enum.map_join("", &get_in(&1, ["plain_text"]))
  end

  def title_text(property) when is_map(property) do
    property
    |> Map.get("title", [])
    |> Enum.map_join("", &get_in(&1, ["plain_text"]))
  end

  def select_name(property) when is_map(property), do: get_in(property, ["select", "name"])
end

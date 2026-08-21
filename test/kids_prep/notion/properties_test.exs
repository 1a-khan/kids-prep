defmodule KidsPrep.Notion.PropertiesTest do
  use ExUnit.Case, async: true

  alias KidsPrep.Notion.Properties

  test "splits long rich text values into Notion-sized chunks" do
    value = String.duplicate("a", 4_501)

    property = Properties.text(value)

    chunks = property.rich_text
    assert length(chunks) == 3
    assert Enum.all?(chunks, &(String.length(&1.text.content) <= 2_000))
    assert Enum.map_join(chunks, "", & &1.text.content) == value
  end

  test "splits long title values into Notion-sized chunks" do
    value = String.duplicate("Title ", 500)

    property = Properties.title(value)

    chunks = property.title
    assert length(chunks) == 2
    assert Enum.all?(chunks, &(String.length(&1.text.content) <= 2_000))
    assert Enum.map_join(chunks, "", & &1.text.content) == value
  end

  test "keeps nil rich text empty" do
    assert Properties.text(nil) == %{rich_text: []}
  end
end

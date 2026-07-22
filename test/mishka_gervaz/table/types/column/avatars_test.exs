defmodule MishkaGervaz.Types.Column.AvatarsTest do
  @moduledoc """
  Tests for the Avatars column type: it renders a related list of people as an overlapping stack,
  reading the raw list off the record rather than the display string the table hands type modules.
  """
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias MishkaGervaz.Table.Types.Column.Avatars

  @ui MishkaGervaz.UIAdapters.Tailwind

  defp person(name, avatar_url \\ nil), do: %{display_name: name, avatar_url: avatar_url}

  defp column(extra \\ %{label_field: :display_name}, source \\ :members) do
    %{name: source, source: source, ui: %{type: :avatars, extra: extra}}
  end

  defp render(record, column \\ column()) do
    # The first arg is whatever the table computed as a display value; Avatars must ignore it.
    rendered_to_string(Avatars.render("ignored", column, record, @ui))
  end

  describe "behaviour implementation" do
    test "implements ColumnType and defines render/4" do
      behaviours = Avatars.__info__(:attributes)[:behaviour] || []
      assert MishkaGervaz.Table.Behaviours.ColumnType in behaviours
      assert function_exported?(Avatars, :render, 4)
    end
  end

  describe "render/4" do
    test "shows the first 3 inline and collapses the rest behind +N" do
      html = render(%{members: Enum.map(~w(Ann Bob Cid Dee Eve), &person/1)})

      assert html =~ "+2"
      # the rest are rendered inline but hidden, revealed on click via a JS class swap
      assert html =~ "hidden"
      assert html =~ "phx-click"
      assert html =~ "phx-click-away"
      assert html =~ "toggle_class"
    end

    test "falls back to the initial of the label when a person has no image" do
      html = render(%{members: [person("dave brown")]})

      assert html =~ ">D<"
      assert html =~ ~s(title="dave brown")
      refute html =~ "<img"
    end

    test "draws an image when one is present, and suppresses its alt text on a dead src" do
      html = render(%{members: [person("Ann", "https://example.com/a.png")]})

      assert html =~ ~s(src="https://example.com/a.png")
      # a broken src otherwise renders the alt at natural size and spills out of the disc
      assert html =~ "text-transparent"
    end

    test "cycles :tints by position so neighbouring initials never match" do
      tints = ["tint-a", "tint-b"]
      html = render(%{members: Enum.map(~w(Ann Bob Cid), &person/1)}, column(%{tints: tints}))

      assert html =~ "tint-a"
      assert html =~ "tint-b"
    end

    test "keeps cycling tints across the collapsed boundary" do
      people = Enum.map(~w(Ann Bob Cid Dee), &person/1)
      html = render(%{members: people}, column(%{tints: ["t0", "t1", "t2", "t3"]}))

      # the 4th person sits in the hidden rest and must still take the 4th tint, not restart at t0
      assert html =~ "t3"
    end

    test "namespaces every id by the column source so multiple stacks stay independent" do
      record = %{id: "rec-1", members: [person("Ann")], owners: [person("Bob")]}

      members_html = render(record, column(%{}, :members))
      owners_html = render(record, column(%{}, :owners))

      assert members_html =~ "gz-avatars-members-rec-1"
      assert owners_html =~ "gz-avatars-owners-rec-1"
      refute members_html =~ "gz-avatars-owners"
      refute owners_html =~ "gz-avatars-members"
    end

    test "no +N when the list fits within max_items" do
      html = render(%{members: [person("Ann")]})

      refute html =~ "phx-click"
      refute html =~ "+1"
    end

    test "respects a custom :max_items from ui.extra" do
      people = Enum.map(~w(Ann Bob Cid Dee), &person/1)

      assert render(%{members: people}, column(%{max_items: 2})) =~ "+2"
    end

    test "renders an empty marker for an empty or nil list" do
      assert render(%{members: []}) =~ "—"
      assert render(%{members: nil}) =~ "—"
    end

    test "reads the image and label from the fields named in ui.extra" do
      record = %{members: [%{name: "Zed", picture: "https://example.com/z.png"}]}
      html = render(record, column(%{image_field: :picture, label_field: :name}))

      assert html =~ ~s(src="https://example.com/z.png")
      assert html =~ ~s(alt="Zed")
    end
  end
end

defmodule MishkaGervaz.UIAdapters.TailwindFieldsTest do
  @moduledoc """
  Every field of the default adapter wears the same design, on and off.

  Two things had drifted. Half the inputs switched themselves off with `bg-gray-100` — Tailwind's
  COOL grey, next to this palette's warm neutrals — so a Category waiting on a Site read as a
  different kind of control rather than the same one, switched off. And four inputs kept a private
  copy of the FILTER look, so inside a form a number or a date sat at 42px on white beside a text
  field at 44px on `#faf9f6`.
  """
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias MishkaGervaz.UIAdapters.Tailwind

  defp render(fun, assigns) do
    %{__changed__: nil, name: "form[thing]", value: "", disabled: false, readonly: false}
    |> Map.merge(assigns)
    |> then(&apply(Tailwind, fun, [&1]))
    |> rendered_to_string()
  end

  @off [
    "text_input",
    "password_input",
    "date_input",
    "datetime_input",
    "number_input",
    "textarea"
  ]

  describe "the switched-off look" do
    test "is the same one for every field kind" do
      for fun <- @off do
        html = render(String.to_existing_atom(fun), %{disabled: true})

        assert html =~ Tailwind.disabled_class(), "#{fun} draws its own disabled state"
        refute html =~ "bg-gray-100", "#{fun} is still on the cool grey"
      end
    end

    test "readonly reads as disabled, because it is the same to a reader" do
      assert render(:text_input, %{readonly: true}) =~ Tailwind.disabled_class()
      assert render(:number_input, %{readonly: true}) =~ Tailwind.disabled_class()
    end

    test "an enabled field carries none of it" do
      refute render(:text_input, %{}) =~ "cursor-not-allowed"
      refute render(:number_input, %{}) =~ "cursor-not-allowed"
    end

    test "it is warm, and it is one string" do
      assert Tailwind.disabled_class() =~ "bg-[#f6f5f2]"
      refute Tailwind.disabled_class() =~ "gray"
    end
  end

  describe "the form look" do
    # A FORM FIELD SITS IN A FIELD CARD (44px, #faf9f6); a filter sits on the page (42px, white).
    # These four asked for neither — they hardcoded the filter one and wore it in both places.
    test "a field with no opinion gets the form variant" do
      for fun <- [:number_input, :date_input, :datetime_input, :password_input] do
        html = render(fun, %{})

        assert html =~ "h-11", "#{fun} is not the form height"
        assert html =~ "bg-[#faf9f6]", "#{fun} is not the form ground"
      end
    end

    test "a filter still asks for the filter variant" do
      html = render(:number_input, %{search: true})

      assert html =~ "h-[42px]"
      assert html =~ "bg-white"
    end

    test "a caller's own class still wins outright" do
      assert render(:number_input, %{class: "my-field"}) =~ ~s(class="my-field)
    end
  end

  # A RELATION FIELD SITS BESIDE THE OTHERS, so it has to be the same field. It used to pass the
  # form look as a literal — a workaround for an adapter that defaulted to the filter one — and the
  # literal had drifted: 12px of radius against 11, semibold against medium.
  describe "a relation field in a form" do
    test "is drawn by the adapter, not by a copy of the adapter" do
      assigns = %{
        __changed__: nil,
        name: :site_id,
        field: nil,
        options: [],
        placeholder: "Select site...",
        value: "",
        disabled: false
      }

      html = rendered_to_string(Tailwind.search_select(assigns))

      assert html =~ "rounded-[11px]"
      assert html =~ "h-11"
      assert html =~ "bg-[#faf9f6]"
      refute html =~ "rounded-[12px]"
    end

    test "and the type no longer carries one" do
      source = File.read!("lib/mishka_gervaz/form/types/field/relation.ex")

      refute source =~ "rounded-[12px]"
    end
  end

  # A DEPENDENT FIELD WAITING ON ITS PARENT is not drawn as an input at all — the standard template
  # puts a stand-in in its place, and that stand-in is the one the design report came in about:
  # `rounded` (4px) and `bg-gray-100`, beside a 44px `rounded-[11px]` field on `#faf9f6`. It needs
  # the adapter's own numbers, and it is asserted here rather than rendered because reaching it
  # needs a mounted component, a loaded form and a parent field with no value.
  describe "the stand-in for a field that is waiting" do
    @template File.read!("lib/mishka_gervaz/form/templates/standard.ex")

    test "wears the field's shape and the switched-off colours" do
      assert @template =~ ~s(flex h-11 w-full items-center gap-2 rounded-[11px] border px-[14px])
      assert @template =~ ~s(border-[#ecebe6] bg-[#f6f5f2] text-[#8a877f])
    end

    test "and none of the old ones" do
      refute @template =~ "bg-gray-100 border-gray-200 text-gray-400"
      refute @template =~ "border-blue-200 text-blue-500"
    end
  end

  describe "the multi-line fields" do
    test "a textarea is the same field as the one above it, minus the fixed height" do
      html = render(:textarea, %{})

      assert html =~ "rounded-[11px]"
      assert html =~ "border-[#ecebe6]"
      assert html =~ "bg-[#faf9f6]"
      refute html =~ "rounded-md"
      refute html =~ "border-gray-300"
    end

    test "the JSON editor is that field in mono" do
      html = render(:json_editor, %{})

      assert html =~ "font-mono"
      assert html =~ "rounded-[11px]"
      refute html =~ "focus:ring-blue-500"
    end
  end
end

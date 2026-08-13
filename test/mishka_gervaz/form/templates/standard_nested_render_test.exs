defmodule MishkaGervaz.Form.Templates.StandardNestedRenderTest do
  @moduledoc """
  Nested sub-fields have to actually RENDER, which nothing asked before.

  Every other test of this path checks the field's shape after transformation — is it `:nested`,
  does it have four sub-fields, is `nested_source` right. All of those passed while the template
  raised on the first sub-field it tried to draw, because `sub_field_input/1` builds its assigns as
  a bare map and `Phoenix.Component.assign/3` refuses anything that is not a socket or a real
  assigns map:

      ** (ArgumentError) assign/3 expects a socket from Phoenix.LiveView/Phoenix.LiveComponent
         or an assigns map from Phoenix.Component as first argument, got: %{disabled: false, …}

  In the browser that is a LiveView crash, which looks to a reader like the page reloading itself
  when they press "Add event".

  So this renders the template for real, one case per sub-field type, because each type is its own
  clause of `sub_field_input/1` and a fix that only reaches the one somebody happened to try is
  worth very little.
  """
  use ExUnit.Case, async: true

  import MishkaGervaz.Test.FormWebHelpers
  import Phoenix.Component, only: [to_form: 2]
  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias MishkaGervaz.Form.Templates.Standard
  alias MishkaGervaz.Resource.Info.Form, as: FormInfo
  alias MishkaGervaz.Test.Resources.NestedForm

  # `render_component/2` wants a function component; the template is one, and rendering it is the
  # whole point — the crash lives between the field's shape and the HTML.
  defp render_form(field) do
    state =
      build_state(
        static_opts: [fields: [field], groups: []],
        mode: :create,
        form: to_form(%{}, as: :form)
      )

    static = %{state.static | notices: []}
    state = %{state | static: static}

    render_component(&Standard.render/1, %{
      static: static,
      state: state,
      ui: MishkaGervaz.UIAdapters.Tailwind,
      myself: nil,
      uploads: %{}
    })
  end

  describe "a nested field draws its sub-fields" do
    test "an embedded array renders without raising" do
      html = render_form(FormInfo.field(NestedForm, :items))

      assert is_binary(html)
      assert html != ""
    end

    test "a map-based nested field renders without raising" do
      html = render_form(FormInfo.field(NestedForm, :tags))

      assert is_binary(html)
      assert html != ""
    end
  end

  # A CLASS IS AN ADDITION, NOT A SWAP. Six resources in this project write
  # `class "font-mono text-sm"` on a code sub-field; none of them means "and drop the border".
  describe "a sub-field's own class" do
    test "is added to the adapter's, not swapped for it" do
      base = FormInfo.field(NestedForm, :tags)

      field =
        Map.update!(base, :nested_fields, fn [first | rest] ->
          [first |> Map.put(:type, :text) |> Map.put(:class, "font-mono") | rest]
        end)

      html = render_form(field)

      assert html =~ "font-mono"
      assert html =~ "rounded-[11px]", "the adapter's own styling has to survive"
    end

    test "a textarea keeps the adapter's multiline styling too" do
      base = FormInfo.field(NestedForm, :tags)

      field =
        Map.update!(base, :nested_fields, fn [first | rest] ->
          [first |> Map.put(:type, :textarea) |> Map.put(:class, "font-mono") | rest]
        end)

      html = render_form(field)

      assert html =~ "font-mono"
      assert html =~ "rounded-[11px]"
    end

    test "no class named leaves the adapter's default alone" do
      base = FormInfo.field(NestedForm, :tags)

      field =
        Map.update!(base, :nested_fields, fn [first | rest] ->
          [first |> Map.put(:type, :text) |> Map.put(:class, nil) | rest]
        end)

      assert render_form(field) =~ "rounded-[11px]"
    end
  end

  # ONE CLAUSE PER TYPE, so a fix that only reaches `:text` cannot pass for a fix.
  describe "every sub-field type its own clause draws" do
    setup do
      %{base: FormInfo.field(NestedForm, :tags)}
    end

    for type <- [
          :text,
          :textarea,
          :number,
          :select,
          :checkbox,
          :toggle,
          :date,
          :datetime,
          :range,
          :json
        ] do
      test "#{type}", %{base: base} do
        type = unquote(type)

        field =
          Map.update!(base, :nested_fields, fn [first | rest] ->
            [%{first | type: type} | rest]
          end)

        assert is_binary(render_form(field))
      end
    end
  end
end

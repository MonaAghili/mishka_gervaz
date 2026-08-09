defmodule MishkaGervaz.Form.Web.State.ApplyPresentationTest do
  @moduledoc """
  A mount's own presentation choices, over the ones the resource declared.

  The resource has one `form` section; the surfaces that mount it do not know the same things. The
  Media library has to ask which site a file belongs to. The page builder's Assets sheet already
  knows, because the page being edited belongs to one — so it hides the field and has no Create
  button, because its dropzone is the submit.

  What is pinned here is that BOTH of those are opt-in: a mount that passes neither assign gets a
  state identical to the one it got before this existed.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Form.Web.State
  alias MishkaGervaz.Form.Web.State.Static

  defp state(fields, groups \\ []) do
    %State{
      static: %Static{
        id: "form",
        resource: Some.Resource,
        fields: fields,
        groups: groups,
        submit: %{create: %{label: "Create"}}
      },
      mode: :create
    }
  end

  defp field(name), do: %{name: name, type: :text}

  describe "hidden_fields" do
    test "a hidden field leaves the field list" do
      result =
        [field(:site_id), field(:media_category_id), field(:featured)]
        |> state()
        |> State.apply_presentation(%{hidden_fields: [:site_id]})

      assert Enum.map(result.static.fields, & &1.name) == [:media_category_id, :featured]
    end

    # A GROUP CARRIES THE FIELD TWICE — once as a name, once resolved — and the template renders the
    # resolved ones. Dropping only one of the two leaves the field on screen or leaves the group
    # claiming a field that no longer exists.
    test "it leaves the groups that named it, in both forms" do
      fields = [field(:site_id), field(:media_category_id)]

      groups = [
        %{
          name: :upload_fields,
          fields: [:site_id, :media_category_id],
          resolved_fields: fields
        }
      ]

      result =
        fields
        |> state(groups)
        |> State.apply_presentation(%{hidden_fields: [:site_id]})

      assert [%{fields: [:media_category_id], resolved_fields: [%{name: :media_category_id}]}] =
               result.static.groups
    end

    test "hiding nothing changes nothing" do
      original = state([field(:site_id)], [%{name: :g, fields: [:site_id]}])

      assert State.apply_presentation(original, %{}) == original
      assert State.apply_presentation(original, %{hidden_fields: []}) == original
      assert State.apply_presentation(original, %{hidden_fields: nil}) == original
    end

    test "a name no field has is not an error" do
      original = state([field(:featured)])

      assert State.apply_presentation(original, %{hidden_fields: [:nonexistent]}) == original
    end
  end

  describe "submit" do
    test "a form draws its submit row unless the mount says otherwise" do
      assert state([]).static.submit_visible?
      assert State.apply_presentation(state([]), %{}).static.submit_visible?
      assert State.apply_presentation(state([]), %{submit: true}).static.submit_visible?
    end

    test "false hides it" do
      refute State.apply_presentation(state([]), %{submit: false}).static.submit_visible?
    end

    # THE BUTTON GOES, THE ACTION STAYS. `Events.do_handle("save", …)` asks the SUBMIT CONFIG whether
    # the save is allowed; clearing that instead of the flag would make a dropzone-submitted form
    # silently unsubmittable.
    test "hiding the row leaves the submit config alone" do
      result = State.apply_presentation(state([]), %{submit: false})

      assert result.static.submit == %{create: %{label: "Create"}}
    end
  end

  test "both at once" do
    result =
      [field(:site_id), field(:featured)]
      |> state()
      |> State.apply_presentation(%{hidden_fields: [:site_id], submit: false})

    assert Enum.map(result.static.fields, & &1.name) == [:featured]
    refute result.static.submit_visible?
  end

  test "assigns that are not a map are ignored" do
    original = state([field(:site_id)])

    assert State.apply_presentation(original, nil) == original
  end

  # THE FLAG IS ONLY WORTH SETTING IF SOMETHING READS IT, and the two readers need a mounted
  # LiveComponent to exercise — so what is asserted is the wiring, at the lines that make it.
  describe "the wiring" do
    test "the standard template has a clause for a hidden submit row" do
      source = File.read!("lib/mishka_gervaz/form/templates/standard.ex")

      assert source =~ "defp render_submit(%{static: %{submit_visible?: false}} = assigns)"
    end

    test "the component applies a mount's choices at init" do
      source = File.read!("lib/mishka_gervaz/form/web/live.ex")

      assert source =~ "State.apply_presentation(assigns)"
    end
  end
end

defmodule MishkaGervaz.Form.Types.Field.MultiSelectTest do
  @moduledoc "Direct tests for the `:multi_select` field type."
  use ExUnit.Case, async: true

  alias MishkaGervaz.Form.Types.Field.MultiSelect

  test "render/2" do
    assert MultiSelect.render(%{}, %{}) == %{}
  end

  test "parse_params/2 passes through" do
    assert MultiSelect.parse_params(["a"], %{}) == ["a"]
  end

  test "default_ui/0" do
    assert MultiSelect.default_ui() == %{type: :multi_select}
  end
end

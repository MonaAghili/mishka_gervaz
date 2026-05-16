defmodule MishkaGervaz.Form.Types.Field.HiddenTest do
  @moduledoc "Direct tests for the `:hidden` field type."
  use ExUnit.Case, async: true

  alias MishkaGervaz.Form.Types.Field.Hidden

  test "render/2 returns assigns unchanged" do
    assert Hidden.render(%{n: 1}, %{}) == %{n: 1}
  end

  test "parse_params/2 passes through" do
    assert Hidden.parse_params("v", %{}) == "v"
  end

  test "default_ui/0" do
    assert Hidden.default_ui() == %{type: :hidden}
  end
end

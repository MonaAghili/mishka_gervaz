defmodule MishkaGervaz.Form.Types.Field.TextareaTest do
  @moduledoc "Direct tests for the `:textarea` field type."
  use ExUnit.Case, async: true

  alias MishkaGervaz.Form.Types.Field.Textarea

  test "render/2 returns assigns unchanged" do
    assert Textarea.render(%{x: 1}, %{}) == %{x: 1}
  end

  test "parse_params/2 passes through" do
    assert Textarea.parse_params("x", %{}) == "x"
  end

  test "default_ui/0" do
    assert Textarea.default_ui() == %{type: :textarea}
  end
end

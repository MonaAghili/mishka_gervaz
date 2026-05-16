defmodule MishkaGervaz.Form.Types.Field.ArrayOfMapsTest do
  @moduledoc "Direct tests for the `:array_of_maps` field type."
  use ExUnit.Case, async: true

  alias MishkaGervaz.Form.Types.Field.ArrayOfMaps

  test "render/2" do
    assert ArrayOfMaps.render(%{}, %{}) == %{}
  end

  test "parse_params/2 passes through" do
    assert ArrayOfMaps.parse_params([%{}], %{}) == [%{}]
  end

  test "default_ui/0" do
    assert ArrayOfMaps.default_ui() == %{type: :array_of_maps}
  end
end

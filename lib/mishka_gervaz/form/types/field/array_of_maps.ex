defmodule MishkaGervaz.Form.Types.Field.ArrayOfMaps do
  @moduledoc """
  Array-of-maps repeatable field type.

  ## Example

      field :rows, :array_of_maps do
        ui do
          add_label "+ Add row"
          remove_label "Remove"
        end
      end

  See `MishkaGervaz.Form.Behaviours.FieldType` and `MishkaGervaz.Form.Types.Field`.
  """

  @behaviour MishkaGervaz.Form.Behaviours.FieldType

  @impl true
  def render(assigns, _config), do: assigns

  @impl true
  def parse_params(value, _config), do: value

  @impl true
  def default_ui, do: %{type: :array_of_maps}
end

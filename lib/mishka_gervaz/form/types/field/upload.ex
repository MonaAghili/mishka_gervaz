defmodule MishkaGervaz.Form.Types.Field.Upload do
  @moduledoc """
  Upload field type for inline positioning of uploads within form fields.

  ## Example

      fields do
        field :cover, :upload do
          ui do label "Cover image" end
        end
      end

      uploads do
        upload :cover do
          accept "image/*"
          max_entries 1
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
  def default_ui, do: %{type: :upload}
end

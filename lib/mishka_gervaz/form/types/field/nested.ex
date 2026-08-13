defmodule MishkaGervaz.Form.Types.Field.Nested do
  @moduledoc """
  Nested / embedded form field type. Used for `inputs_for` and constrained-map fields.

  ## Example

      field :seo_tags, :nested do
        ui do
          add_label "+ Add SEO tag"
          remove_label "Remove"
        end

        nested_field :tag do
          ui do placeholder "meta, link, script" end
        end

        nested_field :content, :textarea do
          ui do rows 3 end
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
  def default_ui, do: %{type: :nested}
end

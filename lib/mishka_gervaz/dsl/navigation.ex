defmodule MishkaGervaz.Dsl.Navigation do
  @moduledoc """
  DSL section for domain-level navigation configuration.

  Defines menu groups and navigation structure for admin UI.

  Used by `MishkaGervaz.Domain` extension.

  See `MishkaGervaz.Domain`, `MishkaGervaz.Entities.MenuGroup`.
  """

  alias MishkaGervaz.Entities.MenuGroup

  defp menu_group_entity do
    %Spark.Dsl.Entity{
      name: :menu_group,
      describe: "A menu group in the admin navigation.",
      target: MenuGroup,
      args: [:name],
      schema: MenuGroup.opt_schema(),
      transform: {MenuGroup, :transform, []}
    }
  end

  @schema []

  @doc """
  The `navigation` section of the `MishkaGervaz.Domain` extension.

  Holds the `menu_group` entities that build the admin sidebar:

      mishka_gervaz do
        navigation do
          menu_group :content do
            label "Content"
            icon "hero-document"
            resources [MyApp.Blog.Post]
          end
        end
      end
  """
  def section do
    %Spark.Dsl.Section{
      name: :navigation,
      describe: "Navigation and menu configuration for admin UI.",
      schema: @schema,
      entities: [
        menu_group_entity()
      ]
    }
  end
end

defmodule MishkaGervaz.UIAdapters.MediaGallery do
  @moduledoc """
  UI adapter for media gallery template.

  Extends the Tailwind adapter with gallery-specific styling.
  Override only the components that need different appearance in gallery context.
  """

  use MishkaGervaz.Behaviours.UIAdapter,
    fallback: MishkaGervaz.UIAdapters.Tailwind

  attr :label, :string, default: nil
  attr :class, :string, default: nil
  attr :icon, :string, default: nil

  attr :rest, :global,
    include: ~w(phx-click phx-target phx-value-id phx-value-event phx-value-values data-confirm)

  @doc """
  Gallery-styled button with circular overlay appearance.
  """
  def button(assigns) do
    default_class = "p-2 bg-white rounded-full shadow hover:bg-gray-100"

    assigns =
      assigns
      |> assign(
        :class,
        if(assigns[:class] in [nil, ""], do: default_class, else: assigns[:class])
      )
      |> assign_new(:icon, fn -> nil end)

    ~H"""
    <button
      type="button"
      class={@class}
      title={@label}
      {@rest}
    >
      <.render_icon :if={@icon} name={@icon} class="w-4 h-4" />
      <span :if={!@icon} class="text-xs">{@label}</span>
    </button>
    """
  end

  defp render_icon(assigns) do
    name = assigns[:name] || ""
    class = assigns[:class] || "w-5 h-5"

    if String.starts_with?(name, "hero-") do
      icon_name = String.replace_prefix(name, "hero-", "")
      assigns = %{name: icon_name, class: class}

      ~H"""
      <span class={["hero-#{@name}", @class]}></span>
      """
    else
      assigns = %{class: class}

      ~H"""
      <span class={@class}></span>
      """
    end
  end

  attr :switchable_templates, :list, required: true
  attr :current_template, :any, required: true
  attr :myself, :any, default: nil

  @doc """
  The Gallery/Table switch, drawn as one recessed tray with the active view lifted onto a white tile
  — the same control every card page in the admin shows, so the media library reads as one of them.

  The fallback draws bordered buttons around a bare unsized icon span, which collapses to nothing.
  `switch_template` and the `template` value are Gervaz's contract; only the look is ours.
  """
  def template_switcher(assigns) do
    ~H"""
    <div
      :if={length(@switchable_templates) > 1}
      class="flex flex-none rounded-[11px] border border-[#ecebe6] bg-[#efeee9] p-[3px]"
    >
      <button
        :for={template <- @switchable_templates}
        type="button"
        phx-click="switch_template"
        phx-value-template={template.name()}
        phx-target={@myself}
        title={template.label()}
        aria-pressed={to_string(@current_template.name() == template.name())}
        class={[
          "grid size-[34px] place-items-center rounded-[9px] transition-colors",
          (@current_template.name() == template.name() &&
             "bg-white text-[#4f4bcc] shadow-[0_1px_2px_rgba(30,28,24,0.06)]") ||
            "text-[#8a877f] hover:text-[#3a382f]"
        ]}
      >
        <span class={switcher_icon_class(template.name())} />
      </button>
    </div>
    """
  end

  @doc """
  The glyph a switcher button wears, by template name.

  A plain function, not a component: an unchanged component renders `data-phx-skip` and an empty
  element that lands in a tray the browser is rebuilding, so the icon vanishes on switching back —
  inlined here there is nothing to skip. Each name is written out so the runtime CSS compiler emits
  its mask; a name reaching a class only through a variable is one it never sees.
  """
  @spec switcher_icon_class(atom()) :: String.t()
  def switcher_icon_class(:media_gallery), do: "hero-squares-2x2 size-4"
  def switcher_icon_class(:table), do: "hero-table-cells size-4"
  def switcher_icon_class(_name), do: "hero-squares-2x2 size-4"
end

defmodule MishkaGervaz.UIAdapters.MediaGallery do
  @moduledoc """
  UI adapter for media gallery template.

  Extends the Tailwind adapter with gallery-specific styling. Only `button/1` differs: a gallery
  action is a round white tile floating over a thumbnail rather than a row of labelled controls, and
  it shows its label as text only when it has no icon to show instead. Everything else — including
  the view switcher — falls back to `MishkaGervaz.UIAdapters.Tailwind`.

  Reached through `MishkaGervaz.Table.Templates.MediaGallery`, which swaps to this adapter only when
  the resource has not named one of its own.
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
      <.icon :if={@icon} name={@icon} class="w-4 h-4" />
      <span :if={!@icon} class="text-xs">{@label}</span>
    </button>
    """
  end
end

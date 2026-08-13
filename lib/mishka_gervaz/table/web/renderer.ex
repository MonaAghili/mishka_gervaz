defmodule MishkaGervaz.Table.Web.Renderer do
  @moduledoc """
  Bridge between LiveComponent and Templates.

  This module is a thin orchestrator that:
  - Selects the appropriate template based on state
  - Prepares minimal assigns for the template
  - Delegates rendering to the template

  ## Architecture

      LiveComponent → Renderer (bridge) → Template → Shared (components)

  ## Performance Optimization

  Renderer passes two key assigns to templates:
  - `@static` - Same reference always, LiveView skips re-render (O(1) comparison)
  - `@state` - Changes trigger re-render only for parts using dynamic fields

  Templates should use:
  - `@static.*` for columns, filters, ui_adapter, etc. (no re-render on user interaction)
  - `@state.*` for page, filter_values, selected_ids, etc. (re-renders when changed)

  See `MishkaGervaz.Table.Web.Live`,
  `MishkaGervaz.Table.Web.State`,
  `MishkaGervaz.Table.Templates.Table`,
  `MishkaGervaz.Table.Behaviours.Template`.
  """

  use Phoenix.Component

  @doc """
  Renders the table through the template currently in effect.

  Called by `MishkaGervaz.Table.Web.Live`. Passes `@static`, `@state`, the `@stream` for the
  resource's stream name and an `@empty?` flag, and falls back to the loading state until the
  first read returns.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    state = assigns[:table_state]
    if state, do: render_with_state(assigns, state), else: render_loading(assigns)
  end

  @spec render_with_state(map(), MishkaGervaz.Table.Web.State.t()) ::
          Phoenix.LiveView.Rendered.t()
  defp render_with_state(assigns, state) do
    template = state.template || MishkaGervaz.Table.Templates.Table

    assigns
    |> assign(:static, state.static)
    |> assign(:state, state)
    |> assign(:stream, get_stream(assigns, state.static.stream_name))
    |> assign(:empty?, table_empty?(state))
    |> assign_new(:myself, fn -> nil end)
    |> template.render()
  end

  @spec render_loading(map()) :: Phoenix.LiveView.Rendered.t()
  defp render_loading(assigns) do
    state = assigns[:table_state]
    template = (state && state.template) || MishkaGervaz.Table.Templates.Table
    template.render_loading(assigns)
  end

  @spec get_stream(map(), atom()) :: list() | tuple()
  defp get_stream(assigns, stream_name) do
    case assigns[:streams] do
      %{^stream_name => stream} -> stream
      _ -> []
    end
  end

  @spec table_empty?(MishkaGervaz.Table.Web.State.t()) :: boolean()
  defp table_empty?(state) do
    state.loading == :loaded and state.total_count == 0
  end
end

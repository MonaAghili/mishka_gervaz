defmodule MishkaGervaz.Table.Templates.EmptyStateTest do
  @moduledoc """
  Regression for the table empty state. It is driven by `state.total_count` (the row count the data
  loader maintains for both numbered and infinite pagination) via the renderer's `@empty?`: the
  configured message shows once the table has loaded and holds zero rows, and never while loading, or
  when rows are present (e.g. after a load-more that simply added nothing).
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Table.Web.{Renderer, State}
  alias MishkaGervaz.Test.Resources.NumberedScrollResource

  import Phoenix.LiveViewTest

  defp render_table(state_opts) do
    state = State.init("test-id", NumberedScrollResource, nil)

    state =
      State.update(
        state,
        Keyword.merge([loading: :loaded, has_initial_data?: true, page: 1], state_opts)
      )

    assigns = %{
      table_state: state,
      streams: %{state.static.stream_name => []},
      myself: nil,
      __changed__: %{}
    }

    render_component(&Renderer.render/1, assigns)
  end

  test "shows the empty state once loaded with zero rows" do
    assert render_table(total_count: 0) =~ "No records found"
  end

  test "does not show the empty state when rows are present" do
    refute render_table(total_count: 23) =~ "No records found"
  end

  test "does not flash the empty state before the first load completes" do
    refute render_table(total_count: 0, loading: :initial) =~ "No records found"
  end

  test "does not flash the empty state during a reload" do
    refute render_table(total_count: 0, loading: :loading) =~ "No records found"
  end

  test "does not show the empty state after a failed load (stale count, rows linger)" do
    refute render_table(total_count: 0, loading: :error) =~ "No records found"
  end
end

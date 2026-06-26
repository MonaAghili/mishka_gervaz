defmodule MishkaGervaz.Table.Web.RendererTest do
  @moduledoc """
  Tests for the Renderer module.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Table.Web.Renderer
  alias MishkaGervaz.Table.Web.State
  alias MishkaGervaz.Test.Resources.User

  import Phoenix.LiveViewTest

  # Mock template module for testing
  defmodule MockTemplate do
    use Phoenix.Component

    def render(assigns) do
      # Handle stream which can be list or tuple
      stream_count = stream_length(assigns.stream)
      assigns = assign(assigns, :stream_count, stream_count)

      ~H"""
      <div data-testid="mock-template">
        <span data-static-id={@static.id}></span>
        <span data-state-page={@state.page}></span>
        <span data-stream-count={@stream_count}></span>
        <span data-empty={to_string(@empty?)}></span>
      </div>
      """
    end

    def render_loading(assigns) do
      ~H"""
      <div data-testid="mock-loading">Loading...</div>
      """
    end

    defp stream_length(stream) when is_list(stream), do: length(stream)
    defp stream_length({_, _, items}) when is_list(items), do: length(items)
    defp stream_length(_), do: 0
  end

  defp create_state(opts \\ []) do
    state = State.init("test-id", User, nil)
    template = Keyword.get(opts, :template, MockTemplate)
    State.update(state, Keyword.merge([template: template], opts))
  end

  defp create_assigns(state, opts \\ []) do
    stream_name = state.static.stream_name
    streams = Keyword.get(opts, :streams, %{stream_name => []})

    %{
      table_state: state,
      streams: streams,
      __changed__: %{}
    }
  end

  describe "render/1" do
    test "dispatches to render_with_state when table_state is present" do
      state = create_state()
      assigns = create_assigns(state)

      result = render_component(&Renderer.render/1, assigns)

      assert result =~ ~s(data-testid="mock-template")
      assert result =~ ~s(data-static-id="test-id")
    end

    test "dispatches to render_loading when table_state is nil" do
      assigns = %{table_state: nil, __changed__: %{}}

      result = render_component(&Renderer.render/1, assigns)

      # Uses default Table template's render_loading which shows spinner
      assert result =~ "Loading"
    end

    test "uses default Table template when template is nil" do
      state = create_state(template: nil)
      assigns = create_assigns(state)

      # Should not raise - uses default template
      result = render_component(&Renderer.render/1, assigns)
      # Default template renders table structure
      assert result =~ "table" or result =~ "gervaz"
    end
  end

  describe "assigns preparation" do
    test "passes static from state.static" do
      state = create_state()
      assigns = create_assigns(state)

      result = render_component(&Renderer.render/1, assigns)

      assert result =~ ~s(data-static-id="test-id")
    end

    test "passes state for dynamic fields" do
      state = create_state() |> State.update(page: 5)
      assigns = create_assigns(state)

      result = render_component(&Renderer.render/1, assigns)

      assert result =~ ~s(data-state-page="5")
    end

    test "extracts stream by stream_name" do
      state = create_state()
      stream_name = state.static.stream_name

      mock_stream = [{"id-1", %{id: "1"}}, {"id-2", %{id: "2"}}]
      assigns = create_assigns(state, streams: %{stream_name => mock_stream})

      result = render_component(&Renderer.render/1, assigns)

      assert result =~ ~s(data-stream-count="2")
    end

    test "returns empty list when stream not found" do
      state = create_state()
      assigns = create_assigns(state, streams: %{other_stream: [{"id-1", %{}}]})

      result = render_component(&Renderer.render/1, assigns)

      assert result =~ ~s(data-stream-count="0")
    end

    test "sets myself to nil by default" do
      state = create_state()
      assigns = create_assigns(state)

      # Should not raise when myself is not provided
      result = render_component(&Renderer.render/1, assigns)
      assert result =~ "mock-template"
    end
  end

  # `@empty?` is driven by `state.total_count` (the row count the data loader maintains for both
  # numbered and infinite pagination), not by stream introspection — a LiveView stream can't report
  # its own emptiness, and the old stream-based check both false-positived and false-negatived.
  describe "empty? detection (state.total_count)" do
    test "true once loaded with zero rows" do
      state = create_state(total_count: 0, has_initial_data?: true, loading: :loaded)

      assert render_component(&Renderer.render/1, create_assigns(state)) =~ ~s(data-empty="true")
    end

    test "false when rows are present (e.g. after a load-more that added nothing)" do
      state = create_state(total_count: 23, has_initial_data?: true, loading: :loaded)

      assert render_component(&Renderer.render/1, create_assigns(state)) =~ ~s(data-empty="false")
    end

    test "false before the first load completes" do
      state = create_state(total_count: 0, loading: :initial)

      assert render_component(&Renderer.render/1, create_assigns(state)) =~ ~s(data-empty="false")
    end

    test "false during a reload" do
      state = create_state(total_count: 0, loading: :loading)

      assert render_component(&Renderer.render/1, create_assigns(state)) =~ ~s(data-empty="false")
    end

    test "false after a FAILED load (stale count must not show empty)" do
      state = create_state(total_count: 0, loading: :error)

      assert render_component(&Renderer.render/1, create_assigns(state)) =~ ~s(data-empty="false")
    end
  end

  describe "static/state separation" do
    test "static contains configuration fields" do
      state = create_state()

      assert state.static.id == "test-id"
      assert state.static.resource == User
      assert is_list(state.static.columns)
      assert is_list(state.static.filters)
      assert is_list(state.static.row_actions)
      assert is_list(state.static.bulk_actions)
    end

    test "state contains dynamic fields" do
      state = create_state() |> State.update(page: 3, loading: :loaded)

      assert state.page == 3
      assert state.loading == :loaded
      assert is_map(state.filter_values)
    end

    test "static reference remains same after state update" do
      state = create_state()
      original_static = state.static

      updated_state = State.update(state, page: 5, loading: :loading)

      # Same reference - enables O(1) comparison
      assert updated_state.static == original_static
    end
  end

  describe "template selection" do
    test "uses custom template when set in state" do
      state = create_state(template: MockTemplate)
      assigns = create_assigns(state)

      result = render_component(&Renderer.render/1, assigns)

      assert result =~ "mock-template"
    end

    test "uses Grid template when configured" do
      state = create_state(template: MishkaGervaz.Table.Templates.Grid)

      # Verify template is set correctly in state
      assert state.template == MishkaGervaz.Table.Templates.Grid

      # Grid template would be used for actual rendering
      # (Full render test skipped due to complex template dependencies)
    end
  end
end

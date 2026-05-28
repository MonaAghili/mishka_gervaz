defmodule MishkaGervaz.Table.Web.BulkActionHandlerTest do
  @moduledoc """
  Tests for the bulk action handler, specifically tenant context handling
  in build_bulk_query.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Table.Web.Events.BulkActionHandler
  alias MishkaGervaz.Table.Web.State
  alias MishkaGervaz.Table.Web.State.Static
  alias MishkaGervaz.Resource.Info.Table, as: Info

  describe "build_bulk_query tenant context" do
    test "tenant user query includes tenant" do
      state = build_table_state(master_user?: false, site_id: "site-123")
      resource = state.static.resource

      query = BulkActionHandler.Default.build_bulk_query(resource, state, nil)

      assert query.tenant == "site-123"
    end

    test "master user query has no tenant" do
      state = build_table_state(master_user?: true, site_id: nil)
      resource = state.static.resource

      query = BulkActionHandler.Default.build_bulk_query(resource, state, nil)

      assert is_nil(query.tenant)
    end

    test "tenant user query with exclude filter includes tenant" do
      state = build_table_state(master_user?: false, site_id: "site-456")
      resource = state.static.resource

      query =
        BulkActionHandler.Default.build_bulk_query(
          resource,
          state,
          {:exclude, ["id-1", "id-2"]}
        )

      assert query.tenant == "site-456"
    end

    test "master user query with exclude filter has no tenant" do
      state = build_table_state(master_user?: true, site_id: nil)
      resource = state.static.resource

      query =
        BulkActionHandler.Default.build_bulk_query(
          resource,
          state,
          {:exclude, ["id-1"]}
        )

      assert is_nil(query.tenant)
    end

    test "tenant from current_user site_id is used" do
      state = build_table_state(master_user?: false, site_id: "tenant-abc")
      resource = state.static.resource

      query = BulkActionHandler.Default.build_bulk_query(resource, state, nil)

      assert query.tenant == "tenant-abc"
      assert query.action.name in [:tenant_read, :read]
    end
  end

  describe "build_ash_bulk_opts/2" do
    test "master user without site_id produces no tenant" do
      state = build_table_state(master_user?: true, site_id: nil)

      {opts, effective_type} = BulkActionHandler.build_ash_bulk_opts(state, :update)

      assert opts[:action] == :update
      assert opts[:notify?] == true
      assert opts[:return_records?] == true
      refute Keyword.has_key?(opts, :tenant)
      assert effective_type == :update
    end

    test "user with site_id carries the tenant" do
      state = build_table_state(master_user?: false, site_id: "site-1")

      {opts, _type} = BulkActionHandler.build_ash_bulk_opts(state, :update)

      assert opts[:tenant] == "site-1"
    end

    test "soft-delete destroy action resolves to :soft_delete" do
      state = build_table_state(resource: MishkaGervaz.Test.DataLoader.ArchivableResource)

      {_opts, effective_type} = BulkActionHandler.build_ash_bulk_opts(state, :destroy)

      assert effective_type == :soft_delete
    end

    test "hard destroy stays :destroy" do
      state = build_table_state()

      {_opts, effective_type} = BulkActionHandler.build_ash_bulk_opts(state, :destroy)

      assert effective_type == :destroy
    end
  end

  describe "build_read_opts/1" do
    test "master user gets no tenant" do
      state = build_table_state(master_user?: true, site_id: nil)

      opts = BulkActionHandler.build_read_opts(state)

      refute Keyword.has_key?(opts, :tenant)
      assert opts[:actor] == state.current_user
    end

    test "tenant user carries the tenant" do
      state = build_table_state(master_user?: false, site_id: "site-9")

      opts = BulkActionHandler.build_read_opts(state)

      assert opts[:tenant] == "site-9"
    end
  end

  describe "resolve_action_spec/2" do
    test "picks master action from a tuple for master users" do
      assert BulkActionHandler.resolve_action_spec({:m, :t}, true) == :m
    end

    test "picks tenant action from a tuple for tenant users" do
      assert BulkActionHandler.resolve_action_spec({:m, :t}, false) == :t
    end

    test "passes a plain atom through" do
      assert BulkActionHandler.resolve_action_spec(:custom, true) == :custom
    end

    test "falls back to :update for nil" do
      assert BulkActionHandler.resolve_action_spec(nil, false) == :update
    end
  end

  describe "get_action_type/2" do
    test "returns the action type for a known action" do
      assert BulkActionHandler.get_action_type(MishkaGervaz.Test.Resources.Post, :destroy) ==
               :destroy

      assert BulkActionHandler.get_action_type(MishkaGervaz.Test.Resources.Post, :master_read) ==
               :read
    end

    test "falls back to :update for an unknown action" do
      assert BulkActionHandler.get_action_type(MishkaGervaz.Test.Resources.Post, :nope) == :update
    end
  end

  describe "soft_delete_action?/3" do
    test "true for a soft destroy action" do
      assert BulkActionHandler.soft_delete_action?(
               MishkaGervaz.Test.DataLoader.ArchivableResource,
               :destroy,
               :destroy
             )
    end

    test "false for a hard destroy action" do
      refute BulkActionHandler.soft_delete_action?(
               MishkaGervaz.Test.Resources.Post,
               :destroy,
               :destroy
             )
    end

    test "false for non-destroy action types" do
      refute BulkActionHandler.soft_delete_action?(
               MishkaGervaz.Test.Resources.Post,
               :update,
               :update
             )
    end
  end

  describe "adapt_lifecycle_args/4" do
    test "appends the socket for a 3-arity hook" do
      key = {:on_bulk_action_success, :archive}
      hooks = %{key => fn _a, _b, _c -> :ok end}

      assert BulkActionHandler.adapt_lifecycle_args(hooks, key, [:summary, :state], :sock) ==
               [:summary, :state, :sock]
    end

    test "leaves args untouched for a 2-arity hook" do
      key = {:on_bulk_action_success, :archive}
      hooks = %{key => fn _a, _b -> :ok end}

      assert BulkActionHandler.adapt_lifecycle_args(hooks, key, [:summary, :state], :sock) ==
               [:summary, :state]
    end

    test "leaves args untouched when the key is absent" do
      assert BulkActionHandler.adapt_lifecycle_args(%{}, {:p, :n}, [:a], :sock) == [:a]
    end

    test "leaves args untouched when hooks is not a map" do
      assert BulkActionHandler.adapt_lifecycle_args(nil, {:p, :n}, [:a], :sock) == [:a]
    end
  end

  describe "builtin_enabled?/2" do
    test "reads the flag from the __builtins__ map" do
      state = build_table_state(hooks: %{__builtins__: %{clear_selection_after_bulk: true}})
      assert BulkActionHandler.builtin_enabled?(state, :clear_selection_after_bulk)
    end

    test "false when the builtin flag is disabled" do
      state = build_table_state(hooks: %{__builtins__: %{clear_selection_after_bulk: false}})
      refute BulkActionHandler.builtin_enabled?(state, :clear_selection_after_bulk)
    end

    test "defaults clear_selection_after_bulk to true without a __builtins__ map" do
      state = build_table_state(hooks: %{})
      assert BulkActionHandler.builtin_enabled?(state, :clear_selection_after_bulk)
      refute BulkActionHandler.builtin_enabled?(state, :some_other_builtin)
    end
  end

  describe "apply_lifecycle_with_default/6" do
    test "applies the default when no hook is configured" do
      state = build_table_state(hooks: %{})

      result =
        BulkActionHandler.apply_lifecycle_with_default(
          state,
          :on_bulk_action_success,
          %{name: :archive},
          [%{}, state],
          socket(),
          &Phoenix.Component.assign(&1, :default_ran, true)
        )

      assert result.assigns.default_ran == true
    end

    test "applies the default when the hook returns a plain socket" do
      key = {:on_bulk_action_success, :archive}
      hooks = %{key => fn _s, _st, sock -> Phoenix.Component.assign(sock, :hook_ran, true) end}
      state = build_table_state(hooks: hooks)

      result =
        BulkActionHandler.apply_lifecycle_with_default(
          state,
          :on_bulk_action_success,
          %{name: :archive},
          [%{}, state],
          socket(),
          &Phoenix.Component.assign(&1, :default_ran, true)
        )

      assert result.assigns.hook_ran == true
      assert result.assigns.default_ran == true
    end

    test "skips the default when the hook returns {:halt, socket}" do
      key = {:on_bulk_action_success, :archive}

      hooks = %{
        key => fn _s, _st, sock -> {:halt, Phoenix.Component.assign(sock, :hook_ran, true)} end
      }

      state = build_table_state(hooks: hooks)

      result =
        BulkActionHandler.apply_lifecycle_with_default(
          state,
          :on_bulk_action_success,
          %{name: :archive},
          [%{}, state],
          socket(),
          &Phoenix.Component.assign(&1, :default_ran, true)
        )

      assert result.assigns.hook_ran == true
      refute Map.get(result.assigns, :default_ran)
    end

    test "returns the socket untouched for a nil action" do
      state = build_table_state(hooks: %{})

      result =
        BulkActionHandler.apply_lifecycle_with_default(
          state,
          :on_bulk_action_success,
          nil,
          [],
          socket(),
          &Phoenix.Component.assign(&1, :default_ran, true)
        )

      refute Map.get(result.assigns, :default_ran)
    end
  end

  describe "apply_lifecycle_socket/5" do
    test "applies the hook result with no default flash" do
      key = {:on_bulk_action_success, :archive}
      hooks = %{key => fn _s, _st, sock -> Phoenix.Component.assign(sock, :hook_ran, true) end}
      state = build_table_state(hooks: hooks)

      result =
        BulkActionHandler.apply_lifecycle_socket(
          state,
          :on_bulk_action_success,
          %{name: :archive},
          [%{}, state],
          socket()
        )

      assert result.assigns.hook_ran == true
    end

    test "returns the socket unchanged when no hook is configured" do
      state = build_table_state(hooks: %{})
      s = socket()

      result =
        BulkActionHandler.apply_lifecycle_socket(
          state,
          :on_bulk_action_success,
          %{name: :archive},
          [%{}, state],
          s
        )

      assert result == s
    end
  end

  defp socket, do: %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}

  defp build_table_state(opts \\ []) do
    master_user? = Keyword.get(opts, :master_user?, false)
    site_id = Keyword.get(opts, :site_id)
    archive_status = Keyword.get(opts, :archive_status, :active)
    resource = Keyword.get(opts, :resource, MishkaGervaz.Test.Resources.Post)
    hooks = Keyword.get(opts, :hooks, %{})

    config = Info.config(resource)

    static = %Static{
      id: "test-table",
      resource: resource,
      stream_name: :test_stream,
      config: config,
      columns: [],
      filters: [],
      row_actions: [],
      row_action_dropdowns: [],
      row_actions_layout: :inline,
      bulk_actions: [],
      ui_adapter: MishkaGervaz.UIAdapters.Tailwind,
      ui_adapter_opts: [],
      switchable_templates: [],
      template_options: %{},
      features: [],
      filter_groups: [],
      filter_mode: :inline,
      pagination_ui: :simple,
      theme: nil,
      sortable_columns: [],
      sort_field_map: %{},
      hooks: hooks,
      url_sync_config: nil,
      page_size: 20
    }

    current_user =
      if site_id do
        %{id: "user-1", site_id: site_id, role: :admin}
      else
        %{id: "user-1", site_id: nil, role: :admin}
      end

    %State{
      static: static,
      current_user: current_user,
      master_user?: master_user?,
      preload_aliases: %{},
      supports_archive: false,
      template: MishkaGervaz.Table.Templates.Standard,
      loading: :loaded,
      loading_type: :full,
      has_initial_data?: true,
      records_result: nil,
      page: 1,
      has_more?: false,
      total_count: 0,
      total_pages: 1,
      filter_values: %{},
      sort_fields: [],
      archive_status: archive_status,
      relation_filter_state: %{},
      selected_ids: MapSet.new(),
      excluded_ids: MapSet.new(),
      select_all?: false,
      expanded_id: nil,
      expanded_data: nil,
      path_params: %{},
      base_path: "/test",
      preserved_params: %{},
      saved_active_state: nil,
      saved_archived_state: nil
    }
  end
end

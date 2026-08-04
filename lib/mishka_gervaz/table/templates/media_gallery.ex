defmodule MishkaGervaz.Table.Templates.MediaGallery do
  @moduledoc """
  Media gallery template for image/file-heavy data.

  Optimized for displaying images, videos, and files with:
  - Thumbnail grid with hover preview
  - Lightbox for full-size viewing
  - File type icons for non-image files
  - Quick actions overlay

  ## Features
  - `:filter` - Filter by file type, date, etc.
  - `:select` - Multi-select for bulk operations
  - `:bulk_actions` - Bulk download, delete, move
  - `:paginate` - Infinite scroll preferred
  - `:expand` - Lightbox expansion

  ## Column-Based Layout

  MediaGallery uses the columns DSL to determine what to display:
  - First visible column becomes the thumbnail image
  - Remaining visible columns are rendered below the thumbnail in order

  Use `visible fn state -> state.template.name() == :media_gallery end` to show columns
  only in MediaGallery, or `visible fn state -> state.template.name() == :table end`
  for Table-only columns.

  ## Options
  - `:columns` - Number of grid columns (3, 4, 6, or 8)

  ## Performance
  Uses `@static.*` for columns, ui_adapter, etc. (no re-render on user interaction)
  Uses `@state.*` for page, filter_values, etc. (re-renders when changed)

  See `MishkaGervaz.Table.Behaviours.Template`,
  `MishkaGervaz.Table.Templates.Shared`,
  `MishkaGervaz.Table.Templates.Table` (sibling), and
  `MishkaGervaz.UIAdapters.MediaGallery` (paired UI adapter).
  """

  use MishkaGervaz.Table.Behaviours.Template
  use MishkaGervaz.Messages

  import MishkaGervaz.Helpers,
    only: [dynamic_component: 1, get_visible_columns: 2, accessible?: 2]

  alias MishkaGervaz.Table.Templates.Shared
  alias Phoenix.LiveView.JS

  @impl true
  def name, do: :media_gallery

  @impl true
  def label, do: "Gallery"

  @doc """
  The switcher draws this glyph for the gallery view.

  A grid of squares rather than a photo, matching every other card view in the admin so the
  Table/Cards switch reads the same wherever it appears. Only the switcher asks for this.
  """
  @impl true
  def icon, do: "hero-squares-2x2"

  @impl true
  def description, do: "Image and media gallery with thumbnails"

  @impl true
  def features do
    [:filter, :select, :bulk_actions, :paginate, :expand]
  end

  @impl true
  def default_options do
    [columns: 6]
  end

  @impl true
  def render(assigns) do
    static = %{assigns.static | ui_adapter: gallery_ui_adapter(assigns.static.ui_adapter)}
    state = assigns.state
    features = static.features
    assigns = assign(assigns, :static, static)

    show_checkboxes =
      :select in features and
        static.bulk_actions != [] and
        Shared.has_visible_bulk_actions?(static.bulk_actions, state.archive_status)

    accessible_filters = Enum.filter(static.filters, &accessible?(&1, state))

    show_filters =
      (accessible_filters != [] or state.supports_archive) and :filter in features

    show_pagination = :paginate in features
    show_bulk_actions = :bulk_actions in features and show_checkboxes

    assigns =
      assigns
      |> assign(:show_checkboxes, show_checkboxes)
      |> assign(:show_filters, show_filters)
      |> assign(:show_pagination, show_pagination)
      |> assign(:show_bulk_actions, show_bulk_actions)
      |> assign(:features, features)

    ~H"""
    <div id={@static.id} class="mishka-gervaz-media-gallery">
      <.render_initial_loading
        :if={!@state.has_initial_data? and @state.loading in [:initial, :loading]}
        static={@static}
        state={@state}
      />

      <div :if={@state.has_initial_data? or @state.loading == :loaded}>
        <.render_header static={@static} state={@state} myself={@myself} />

        <.render_filters :if={@show_filters} static={@static} state={@state} myself={@myself} />

        <.render_selection_toolbar
          :if={@show_checkboxes}
          static={@static}
          state={@state}
          myself={@myself}
        />

        <.render_bulk_actions
          :if={@show_bulk_actions}
          static={@static}
          state={@state}
          myself={@myself}
        />

        <div class="relative" style="isolation: isolate;">
          <.render_loading_overlay
            :if={
              @state.has_initial_data? and @state.loading == :loading and
                @state.loading_type == :reset
            }
            static={@static}
            state={@state}
          />

          <div id={"#{@static.stream_name}"} phx-update="stream" class={gallery_classes(@static)}>
            <.render_item
              :for={{id, record} <- @stream}
              id={id}
              record={record}
              static={@static}
              state={@state}
              show_checkboxes={@show_checkboxes}
              myself={@myself}
            />
          </div>
        </div>

        <.render_empty :if={@empty?} static={@static} state={@state} myself={@myself} />

        <.render_pagination :if={@show_pagination} static={@static} state={@state} myself={@myself} />
      </div>
    </div>
    """
  end

  @impl true
  def render_header(assigns) do
    assigns = assign(assigns, :total_count, assigns.state.total_count || 0)

    ~H"""
    <div class="mb-[14px] flex flex-wrap items-center justify-between gap-4">
      <span class="text-[12.5px] font-semibold text-[#8a877f]">
        {dngettext("mishka_gervaz", "%{count} file", "%{count} files", @total_count,
          count: @total_count
        )}
      </span>
      <div class="flex items-center gap-[10px]">
        <.dynamic_component
          :if={@state.supports_archive}
          module={@static.ui_adapter}
          function={:archive_toggle}
          table_id={@static.id}
          archive_status={@state.archive_status}
          myself={@myself}
        />
        <Shared.render_template_switcher
          :if={@static.switchable_templates not in [nil, []]}
          switchable_templates={@static.switchable_templates}
          current_template={@state.template}
          ui_adapter={@static.ui_adapter}
          myself={@myself}
        />
      </div>
    </div>
    """
  end

  defp render_selection_toolbar(assigns) do
    checkbox_assigns =
      %{__changed__: %{}}
      |> assign(:id, assigns.static.id <> "-gallery-select-all")
      |> assign(:name, "select_all_gallery")
      |> assign(:value, "all")
      |> assign(:checked, assigns.state.select_all?)
      |> assign(
        :class,
        "gervaz-select-all-checkbox size-4 cursor-pointer rounded accent-[#5b57d6]"
      )
      |> assign(:label, dgettext("mishka_gervaz", "Select all"))

    assigns = assign(assigns, :checkbox_assigns, checkbox_assigns)

    ~H"""
    <div class="mb-3.5 flex items-center gap-4 px-0.5 [&_label]:flex [&_label]:cursor-pointer [&_label]:items-center [&_label]:gap-[9px] [&_span]:text-[12.5px]! [&_span]:font-semibold [&_span]:text-[#5c5a54]">
      <.dynamic_component
        module={@static.ui_adapter}
        function={:checkbox}
        phx-click={toggle_all_js(@state.select_all?, @static.id)}
        phx-target={@myself}
        {@checkbox_assigns}
      />
    </div>
    """
  end

  defp toggle_all_js(current_select_all, scope) do
    js = JS.push("toggle_select_all")

    if current_select_all do
      Shared.uncheck_all(js, scope)
    else
      Shared.check_all_gallery(js, scope)
    end
  end

  @impl true
  def render_item(assigns) do
    static = assigns.static
    state = assigns.state
    record = assigns.record

    thumbnail_column =
      static.columns
      |> get_visible_columns(state)
      |> List.first()

    is_checked =
      if state.select_all? do
        not MapSet.member?(state.excluded_ids, record.id)
      else
        MapSet.member?(state.selected_ids, record.id)
      end

    checkbox_assigns =
      %{__changed__: %{}}
      |> assign(:name, "select_media")
      |> assign(:value, record.id)
      |> assign(:checked, is_checked)
      |> assign(:class, "gervaz-media-checkbox size-4 cursor-pointer rounded accent-[#5b57d6]")

    visible_row_actions =
      static.row_actions
      |> Shared.non_accordion_actions()
      |> Enum.filter(&Shared.action_visible?(&1, record, state))

    image_url =
      case thumbnail_column do
        nil -> nil
        column -> get_column_value(column, record, state) |> cache_bust_url(record)
      end

    assigns =
      assigns
      |> assign(:is_checked, is_checked)
      |> assign(:checkbox_assigns, checkbox_assigns)
      |> assign(:visible_row_actions, visible_row_actions)
      |> assign(:custom_card_class, get_custom_card_class(static, record))
      |> assign(:image_url, image_url)
      |> assign(:is_image, is_image_url?(image_url))
      |> assign(:tint, type_tint(record))
      |> assign(:media_type, media_type(record))
      |> assign(:ext, media_ext(record))
      |> assign(:filename, media_name(record))
      |> assign(:size_label, media_size(record))
      |> assign(:category, media_category(record))
      |> assign(:date_label, media_date(record))
      |> assign(:featured?, media_featured?(record))

    ~H"""
    <div
      id={@id}
      class={[
        "group overflow-hidden rounded-[14px] border bg-white shadow-[0_1px_2px_rgba(30,28,24,0.04)] transition-colors",
        cond do
          @is_checked -> "border-[#dcdbf5] ring-1 ring-[#5b57d6]"
          @featured? -> "border-[#f0e2c4] ring-1 ring-[#e6b422]"
          true -> "border-[#ecebe6] hover:border-[#dcdbf5]"
        end,
        @custom_card_class
      ]}
    >
      <div
        class={["relative isolate aspect-square", @tint]}
        phx-click="expand"
        phx-value-id={@record.id}
        phx-target={@myself}
      >
        <%!-- The type-icon tile sits under the image so it is what shows when there is no image, or
              when one is declared but its file has gone (the img hides itself on error). The glyph is
              inline SVG, not a hero-icon: its name reaches the class through a variable, and the
              runtime compiler only emits a mask for a name it can read literally in source. --%>
        <span class="absolute inset-0 flex items-center justify-center">
          <span class="grid size-[52px] place-items-center rounded-[14px] bg-white shadow-[0_2px_6px_rgba(30,28,24,0.06)]">
            <.type_svg type={@media_type} />
          </span>
        </span>

        <%!-- The image sits on top of the tile with no background of its own: until it loads it is
              transparent and the tile shows through, and if its file has gone it hides itself. The
              `phx-update="ignore"` keeps that hide across the stream's patches — otherwise a select
              or a filter re-renders the row and the broken image comes back over the tile. --%>
        <div :if={@image_url && @is_image} id={"#{@id}-thumb"} phx-update="ignore" class="contents">
          <img
            src={@image_url}
            alt=""
            loading="lazy"
            class="absolute inset-0 size-full object-cover"
            onload="this.style.background='#fff';"
            onerror="this.style.display='none';"
          />
        </div>

        <span
          :if={@ext}
          class="absolute bottom-[10px] left-[10px] rounded-md bg-white/85 px-[7px] py-[3px] text-[9px] font-bold uppercase tracking-[0.05em] text-[#5c5a54] shadow-[0_1px_2px_rgba(30,28,24,0.08)]"
        >
          {@ext}
        </span>

        <div class="absolute inset-0 z-10 flex items-center justify-center bg-[#17161a]/0 opacity-0 transition-all group-hover:bg-[#17161a]/25 group-hover:opacity-100">
          <Shared.render_row_actions
            row_actions={@visible_row_actions}
            record={@record}
            static={@static}
            state={@state}
            myself={@myself}
          />
        </div>

        <span :if={@show_checkboxes} class="absolute left-[10px] top-[10px] z-20">
          <.dynamic_component
            module={@static.ui_adapter}
            function={:checkbox}
            phx-click="toggle_select"
            phx-value-id={@record.id}
            phx-target={@myself}
            {@checkbox_assigns}
          />
        </span>

        <span
          :if={@featured?}
          title="Featured"
          class="absolute right-2 top-2 z-20 grid size-7 place-items-center rounded-lg bg-white/85 text-[#e6b422] shadow-[0_1px_2px_rgba(30,28,24,0.08)]"
        >
          <.dynamic_component
            module={@static.ui_adapter}
            function={:icon}
            name="hero-star-solid"
            class="size-[15px]"
          />
        </span>
      </div>

      <div class="px-[13px] py-3">
        <div class="truncate text-[12.5px] font-semibold text-[#1b1a18]" title={@filename}>
          {@filename}
        </div>

        <div class="mt-[5px] flex items-center gap-2 text-[11px]">
          <span class="flex-none font-['Space_Grotesk'] font-semibold text-[#8a877f]">
            {@size_label}
          </span>
          <span :if={@category} class="size-[3px] flex-none rounded-full bg-[#c3c0b8]"></span>
          <span :if={@category} class="min-w-0 truncate font-medium text-[#a8a5a0]">
            {@category}
          </span>
        </div>

        <div
          :if={@date_label}
          class="mt-1.5 font-['Space_Grotesk'] text-[10px] font-medium text-[#c3c0b8]"
        >
          {@date_label}
        </div>
      </div>
    </div>
    """
  end

  @tints %{
    images: "bg-[#eef1fc] text-[#4f4bcc]",
    videos: "bg-[#fbe9e7] text-[#b3433a]",
    documents: "bg-[#eaf6ee] text-[#177a53]"
  }

  defp type_tint(record), do: Map.get(@tints, media_type(record), "bg-[#f2f1ec] text-[#8a877f]")

  attr :type, :atom, default: nil

  defp type_svg(%{type: :images} = assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.7"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-[26px]"
      aria-hidden="true"
    >
      <rect x="3" y="4" width="18" height="16" rx="2" /><circle cx="8.5" cy="9" r="1.6" /><path d="m3 16 5-4 4 3 4-4 5 4" />
    </svg>
    """
  end

  defp type_svg(%{type: :videos} = assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.7"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-[26px]"
      aria-hidden="true"
    >
      <rect x="3" y="5" width="18" height="14" rx="2.5" /><path d="M10 9.5v5l4-2.5z" />
    </svg>
    """
  end

  defp type_svg(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.7"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-[26px]"
      aria-hidden="true"
    >
      <path d="M8 3h6l4 4v13a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z" /><path d="M14 3v5h4M9.5 13h5M9.5 16h4" />
    </svg>
    """
  end

  defp media_type(%{type: type}) when is_atom(type) and not is_nil(type), do: type
  defp media_type(_record), do: nil

  defp media_ext(%{format: format}) when is_binary(format) and format != "", do: format
  defp media_ext(_record), do: nil

  defp media_name(%{name: name, format: format})
       when is_binary(name) and is_binary(format),
       do: "#{name}.#{format}"

  defp media_name(%{name: name}) when is_binary(name), do: name
  defp media_name(_record), do: "Untitled"

  defp media_size(%{size: size}) when is_integer(size),
    do: MishkaGervaz.Helpers.format_filesize(size)

  defp media_size(_record), do: "—"

  # Only one of the two category relationships is preloaded — a tenant's own, or a master's
  # tenancy-bypassing alias — so the other is a truthy `%Ash.NotLoaded{}`; find whichever is a record.
  defp media_category(record) do
    Enum.find_value([:media_category, :master_media_category], fn key ->
      case Map.get(record, key) do
        %{name: name} when is_binary(name) -> name
        _absent -> nil
      end
    end)
  end

  defp media_date(%{inserted_at: %DateTime{} = at}), do: Calendar.strftime(at, "%b %d, %Y")
  defp media_date(%{inserted_at: %NaiveDateTime{} = at}), do: Calendar.strftime(at, "%b %d, %Y")
  defp media_date(_record), do: nil

  defp media_featured?(%{featured: true}), do: true
  defp media_featured?(_record), do: false

  defp get_column_value(column, record, state) do
    cond do
      column.static and is_function(column.render, 1) ->
        required_fields = column.requires || [column.name]
        field_map = Map.new(required_fields, fn field -> {field, Map.get(record, field)} end)
        column.render.(field_map)

      is_function(column.render, 1) ->
        value = Map.get(record, column.name)
        column.render.(value)

      is_function(column.render, 2) ->
        value = Map.get(record, column.name)
        column.render.(value, state)

      true ->
        Map.get(record, column.name)
    end
  end

  defp is_image_url?(nil), do: false

  defp is_image_url?("data:image/" <> _), do: true

  defp is_image_url?(url) when is_binary(url) do
    path = url |> String.split("?") |> List.first()
    ext = path |> String.downcase() |> Path.extname()
    ext in ~w(.jpg .jpeg .png .gif .webp .svg)
  end

  defp is_image_url?(_), do: false

  defp cache_bust_url(nil, _record), do: nil

  defp cache_bust_url(url, record) when is_binary(url) do
    case Map.get(record, :updated_at) do
      %DateTime{} = dt -> url <> "?v=#{DateTime.to_unix(dt)}"
      _ -> url
    end
  end

  defp cache_bust_url(url, _record), do: url

  @impl true
  def render_empty(assigns) do
    empty_state = Map.get(assigns.static.config, :empty_state, %{})
    default_empty_state = Map.put_new(empty_state, :icon, "hero-photo")
    assigns = assign(assigns, :empty_state, default_empty_state)
    Shared.render_empty_state(assigns)
  end

  @impl true
  def render_loading(assigns) do
    loading_text =
      (assigns[:static] && assigns.static.pagination_ui.loading_text) ||
        dgettext("mishka_gervaz", "Loading...")

    assigns = assign(assigns, :loading_text, loading_text)

    ~H"""
    <.dynamic_component
      module={@static.ui_adapter}
      function={:loading_state}
      type={:initial}
      style={:spinner}
      text={@loading_text}
      class="py-12 text-center"
    />
    """
  end

  @impl true
  def render_filters(assigns) do
    all_filters =
      Shared.merge_relation_filter_state(
        assigns.static.filters,
        assigns.state.relation_filter_state || %{}
      )

    accessible = Enum.filter(all_filters, &accessible?(&1, assigns.state))

    grid_filters =
      Enum.filter(accessible, &(&1.name in [:search, :type, :site_id]))
      |> Enum.sort_by(&Enum.find_index([:search, :type, :site_id], fn n -> n == &1.name end))

    assigns =
      assigns
      |> assign(:all_filters, all_filters)
      |> assign(:grid_filters, grid_filters)
      |> assign(:featured_filter, Enum.find(accessible, &(&1.name == :featured)))

    ~H"""
    <form
      :if={@grid_filters != [] or @featured_filter}
      id={"#{@static.stream_name}-filter"}
      phx-change="filter"
      phx-target={@myself}
      class="mb-[14px] flex flex-wrap items-end gap-[12px]"
    >
      <Shared.render_filter
        :for={filter <- @grid_filters}
        filter={filter}
        all_filters={@all_filters}
        state={@state}
        static={@static}
        myself={@myself}
      />
      <Shared.render_filter
        :if={@featured_filter}
        filter={@featured_filter}
        all_filters={@all_filters}
        state={@state}
        static={@static}
        myself={@myself}
      />
    </form>
    """
  end

  defp render_initial_loading(assigns) do
    loading_text =
      assigns.static.pagination_ui.loading_text || dgettext("mishka_gervaz", "Loading...")

    assigns = assign(assigns, :loading_text, loading_text)

    ~H"""
    <.dynamic_component
      module={@static.ui_adapter}
      function={:loading_state}
      type={:initial}
      style={:spinner}
      text={@loading_text}
      class="py-12 text-center"
    />
    """
  end

  defp render_loading_overlay(assigns) do
    loading_text =
      assigns.static.pagination_ui.loading_text || dgettext("mishka_gervaz", "Loading...")

    assigns = assign(assigns, :loading_text, loading_text)

    ~H"""
    <div class="absolute inset-0 bg-white/70 flex items-center justify-center z-20 min-h-[200px]">
      <.dynamic_component
        module={@static.ui_adapter}
        function={:loading_state}
        type={:overlay}
        style={:spinner}
        text={@loading_text}
        class="flex items-center gap-2 bg-white px-4 py-2 rounded-lg shadow-md"
      />
    </div>
    """
  end

  # The track never drops a card below its floor unless the viewport itself is narrower, so the count
  # falls on its own — no breakpoint to miss. The `columns` option only sets that floor: a smaller
  # column count means wider cards, so a wider minimum.
  defp gallery_classes(static) do
    options = static.template_options || default_options()

    [
      "grid items-start gap-4",
      track_class(Keyword.get(options, :columns, 4)),
      Keyword.get(options, :class)
    ]
    |> Enum.filter(& &1)
  end

  # WHOLE CLASS NAMES, one clause per floor, because Tailwind's scanner reads SOURCE TEXT. Written
  # with the floor interpolated in, the scanner took the surrounding text literally and emitted a
  # rule for a selector containing `#{floor` — so the gallery got dead CSS and no working track, and
  # every card stretched across the full row instead of tiling.
  #
  # It looked right only while the admin was styled by the in-browser Tailwind JIT, which reads
  # classes off the rendered DOM and never cared how they were assembled. The admin is served a
  # compiled `admin.css` now (`mix admin_css`); a class that exists only after interpolation has
  # nothing to find.
  defp track_class(columns) when columns <= 3,
    do: "grid-cols-[repeat(auto-fill,minmax(min(100%,220px),1fr))]"

  defp track_class(4), do: "grid-cols-[repeat(auto-fill,minmax(min(100%,190px),1fr))]"
  defp track_class(_more), do: "grid-cols-[repeat(auto-fill,minmax(min(100%,150px),1fr))]"

  defp get_custom_card_class(static, record) do
    case get_in(static.config, [:row, :class, :apply]) do
      apply_fn when is_function(apply_fn, 1) -> apply_fn.(record)
      _ -> nil
    end
  end

  defp gallery_ui_adapter(MishkaGervaz.UIAdapters.Tailwind),
    do: MishkaGervaz.UIAdapters.MediaGallery

  defp gallery_ui_adapter(user_adapter), do: user_adapter
end

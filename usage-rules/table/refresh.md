# Table → `refresh`

Auto-reload on a timer, for tables watching something that changes without a broadcast.

```elixir
refresh do
  enabled true
  interval 15_000            # ms; domain default 30_000
  pause_on_interaction true
  show_indicator true
  pause_on_blur true
end
```

| Option | Type | Default | Note |
|---|---|---|---|
| `enabled` | bool | `true` | overrides the domain default |
| `interval` | pos int | `30_000` | milliseconds |
| `pause_on_interaction` | bool | `true` | pause while filtering / selecting |
| `show_indicator` | bool | `true` | visible "refreshing" marker |
| `pause_on_blur` | bool | `true` | pause when the tab loses focus |

## It does nothing without the parent

The timer sends `:gervaz_refresh` to the **parent LiveView** process. Forward it or nothing
reloads:

```elixir
def handle_info(:gervaz_refresh, socket) do
  send_update(MishkaGervaz.Table.Web.Live, id: "posts-table", gervaz_refresh: true)
  {:noreply, socket}
end
```

The component then reloads page 1 with `reset: true` and re-schedules the timer.

## Prefer realtime

If the data is written through Ash with a `pub_sub` notifier, use
[realtime.md](realtime.md) instead — it is push, not poll, and costs one query per real change
rather than one per interval.

## TODO
- [ ] Parent handles `:gervaz_refresh` and calls `send_update(..., gervaz_refresh: true)`
- [ ] `interval` justified — every tick is a full page-1 query per connected reader
- [ ] `realtime` considered first
- [ ] `pause_on_blur` / `pause_on_interaction` left on

## DSL reference

Generated from the schema, always current:

- Resource — [`mishka_gervaz.table.refresh`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-table-refresh)

- Domain — [`mishka_gervaz.table.refresh`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-domain.html#mishka_gervaz-table-refresh)

**Schema:** `MishkaGervaz.Table.Dsl.Refresh` (resource), `Table.Dsl.Defaults` (domain) ·
**Runtime:** `MishkaGervaz.Table.Web.Refresh`

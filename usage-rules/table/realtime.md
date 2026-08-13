# Table → `realtime`

PubSub-driven live updates. An entity — inline (`realtime prefix: "posts"`) or block form.

```elixir
realtime do
  enabled true
  prefix "blog_post"                       # REQUIRED whenever enabled
  pubsub MyApp.PubSub                      # normally set once on the domain
  visible fn record, user -> is_nil(user.site_id) or record.site_id == user.site_id end
end
```

| Option | Type | Default | Note |
|---|---|---|---|
| `enabled` | bool | `true` | |
| `prefix` | string | — | topic prefix — `"posts"` ⇒ `posts:created`, … |
| `pubsub` | `Phoenix.PubSub` module | — | usually inherited from the domain |
| `visible` | `fn record, user -> boolean` | — | arity **2** — filters incoming updates |

`enabled false` on a resource **beats** `true` on the domain: `false` is an answer, not an absence.

## The parent LiveView still has one job

The component subscribes itself, but broadcasts arrive at the **LiveView** process. Forward them:

```elixir
def handle_info(
      %Phoenix.Socket.Broadcast{
        topic: "blog_post" <> _,
        payload: %Ash.Notifier.Notification{} = notification
      },
      socket
    ) do
  send_update(MishkaGervaz.Table.Web.Live, id: "posts-table", pubsub_notification: notification)
  {:noreply, socket}
end
```

Full integration: [../mounting.md](../mounting.md).

## `visible` keeps other tenants out

Without it a master's broadcast can insert a row a tenant must not see. The predicate runs per
incoming record against the current user.

To take control of an update entirely, use the `on_realtime` hook and return `{:halt, socket}`
([hooks.md](hooks.md)).

## TODO
- [ ] `prefix` set (compile fails otherwise)
- [ ] `pubsub` reachable — set on the domain
- [ ] Resource's Ash `pub_sub` notifier actually broadcasts on that prefix
- [ ] Parent LiveView forwards `%Phoenix.Socket.Broadcast{}` via `send_update/2`
- [ ] `visible` declared for any multitenant resource
- [ ] `enabled false` on tables backed by a data layer with nothing to subscribe to

## DSL reference

Generated from the schema, always current:

- Resource — [`mishka_gervaz.table.realtime`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-table-realtime)

- Domain — [`mishka_gervaz.table.realtime`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-domain.html#mishka_gervaz-table-realtime)

**Schema:** `MishkaGervaz.Table.Dsl.Realtime`, `MishkaGervaz.Table.Entities.Realtime` ·
**Verifier:** `Table.Verifiers.ValidateSource`

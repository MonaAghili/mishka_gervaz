# Form → `source`

Which Ash actions run per mode, what is preloaded, and which modes the current user may reach.

```elixir
source do
  actor_key :current_user
  master_check fn user -> is_nil(user.site_id) end
  restricted false                       # true | fn state -> ⇒ the whole form is master-only

  actions do
    create {:master_create, :create}     # all three REQUIRED once the form has any field
    update {:master_update, :update}
    read   {:master_get, :read}
  end

  preload do
    always [:site]
    master [:master_collections, :master_tags]
    tenant [:tenant_collections, :tenant_tags]
  end

  access :create, restricted: true                      # A — per mode, keyword form
  access :update, fn state -> state.master_user? end     # B — per mode, condition form
  access fn mode, state -> mode == :update end           # C — global gate, arity 2
end
```

## `actions`

Atom (both roles) or `{master_action, tenant_action}`, chosen by `master_check`. For a
non-multitenant resource only the second element is used. All three keys are required as soon as
the form declares a field — on the resource or the domain, resource wins per key.

The `read` action is what edit mode fetches the record with; `create` and `update` back the two
modes.

## `master_check` has a fallback here

Unlike the table, the form falls back to `MishkaGervaz.Helpers.master_user?/1`, which is
`site_id == nil`. Declare your own unless that is exactly your rule.

## `preload`

Atoms or `{source, alias}` tuples, in three tiers, so master and tenant can expose different
relationships under the same alias. `preload_aliases` maps them back, so a field's
`derive_value` reads one name for both roles.

> A preloaded relationship's read action must not have `pagination required?: true` — preloads
> pass no limit and it raises `Ash.Error.Invalid.LimitRequired`. This is **compile-checked** on
> the form side: the build fails with the offending relationship named.

## `access`

Gates whether a **mode** is reachable at all. A denied mode leaves the form in `loading: :denied`
rather than rendering fields. Three calling styles:

| Style | Shape | Use |
|---|---|---|
| A | `access :create, restricted: true` | master-only mode |
| B | `access :create, fn state -> … end` | one mode, custom rule |
| C | `access fn mode, state -> … end` | one rule covering both modes |

`restricted true` at the top of `source` gates the whole form instead.

## TODO
- [ ] `create`, `update`, `read` all reachable from the resource or the domain
- [ ] `master_check` declared if `site_id == nil` is not your master test
- [ ] Preloads split by role when the relationship names differ
- [ ] Preloaded read actions use `pagination required?: false`
- [ ] `access` used to close a mode rather than hiding every field individually
- [ ] The page handles a `:denied` form (it renders no fields)

## DSL reference

Generated from the schema, always current:

- Resource — [`mishka_gervaz.form.source`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-source) · [`mishka_gervaz.form.source.actions`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-source-actions) · [`mishka_gervaz.form.source.preload`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-source-preload) · [`mishka_gervaz.form.source.access`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-source-access)

- Domain — [`mishka_gervaz.form.actions`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-domain.html#mishka_gervaz-form-actions)

**Schema:** `MishkaGervaz.Form.Dsl.Source`, `Form.Entities.Access` ·
**Verifiers:** `Form.Verifiers.ValidateSource`, `.ValidatePreloads`

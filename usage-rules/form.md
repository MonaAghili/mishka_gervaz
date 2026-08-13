# MishkaGervaz — Form Rules

The `form` section builds a create/edit form: fields, groups, wizard/tabs steps, uploads,
validation, relation loading and submit buttons. Read [../usage-rules.md](../usage-rules.md)
first — master/tenant, the three slots (`source` / `ui` / `render`), and predicate arities are
assumed everywhere below.

**This file is an index.** Open only the section you are editing.

## Skeleton

```elixir
mishka_gervaz do
  form do
    identity do … end
    source do … end
    fields do … end
    groups do … end
    layout do … end
    uploads do … end
    presentation do … end
    hooks do … end
    state do … end

    submit do … end          # entities, not sections
    data_loader do … end
    events do … end
  end
end
```

The hierarchy is **step → groups → fields**. Groups partition fields; steps partition groups.
A field may sit in at most one group; a group in at most one step.

## Sections

| Section | What it decides | Rules |
|---|---|---|
| `identity` | the form's name — which is also its LiveComponent id | [form/identity.md](form/identity.md) |
| `source` | which Ash actions run, what is preloaded, which modes are reachable | [form/source.md](form/source.md) |
| `fields` | every input: type, validation, relations, nested shapes, auto-discovery | [form/fields.md](form/fields.md) |
| `groups` | which fields sit together, and the grid they sit in | [form/groups.md](form/groups.md) |
| `layout` | standard vs wizard vs tabs, the grid, and the steps | [form/layout.md](form/layout.md) |
| `layout` chrome | header, footer, and positioned notices | [form/chrome.md](form/chrome.md) |
| `uploads` | file uploads, their limits, and existing files in edit mode | [form/uploads.md](form/uploads.md) |
| `submit` | the create / update / cancel buttons and their inheritance | [form/submit.md](form/submit.md) |
| `presentation` | template, UI adapter, features, debounce, theme | [form/presentation.md](form/presentation.md) |
| `hooks` | server lifecycle callbacks and client-side JS commands | [form/hooks.md](form/hooks.md) |
| `state` / `data_loader` / `events` | replacing a builder, loader or event handler | [customization/overrides.md](customization/overrides.md) |

## The five things that fail a build

1. A form with any field needs **`create`, `update` and `read`** actions — on the resource or the domain.
2. Every non-`virtual` field name must be an attribute, relationship, calculation or aggregate.
3. A group may not name a missing field, and no field may appear in two groups.
4. `:wizard` / `:tabs` require steps; `:standard` forbids them; `navigation :free` is invalid with `:wizard`.
5. A preloaded relationship's read action must not have `pagination required?: true`.

Full error text and the fix for each: [troubleshooting.md](troubleshooting.md).

## DSL reference

Generated from the schema, always current:

- Resource — [`mishka_gervaz.form`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form)

- Domain — [`mishka_gervaz.form`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-domain.html#mishka_gervaz-form)

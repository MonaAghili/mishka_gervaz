# Form → `presentation`

Template, UI adapter, which features are on, the global debounce, and the theme slots.

```elixir
presentation do
  template MishkaGervaz.Form.Templates.Standard      # default
  ui_adapter MyAppWeb.UIAdapters.Admin               # default MishkaGervaz.UIAdapters.Tailwind
  ui_adapter_opts component_module: MyAppWeb.Components
  features :all
  debounce 300

  theme do
    form_class "max-w-4xl"
    field_class "rounded-md"
    label_class "text-sm font-medium"
    error_class "text-red-600"
    extra %{}
  end
end
```

| Option | Type | Default | Note |
|---|---|---|---|
| `template` | module | `Form.Templates.Standard` | *where* things go |
| `ui_adapter` | module | `UIAdapters.Tailwind` | *how* they look |
| `ui_adapter_opts` | keyword | `[]` | see the adapter rules |
| `features` | `:all` \| list | `:all` | |
| `debounce` | int (ms) | — | global `phx-debounce`; per-field override in `ui do debounce end` |

`features`: `:validation` · `:uploads` · `:groups` · `:wizard` · `:autosave` · `:inline_errors`.

> ⚠ `features` is resolved onto `state.static.features`, but the built-in
> `MishkaGervaz.Form.Templates.Standard` **does not check it** — narrowing the list changes
> nothing today. It is there for a custom template to honour
> ([../customization/form-templates.md](../customization/form-templates.md)). To actually switch
> a behaviour off, remove the DSL that produces it (drop the `uploads` block, drop the steps).

`theme`: `form_class` · `field_class` · `label_class` · `error_class` · `extra` (map for
template-specific options).

`template`, `features`, `ui_adapter`, `ui_adapter_opts` and every `theme` key are inheritable
from the domain; the resource wins per key.

## Template vs UI adapter

Two orthogonal axes — swapping one never forces the other. Writing either:
[../customization/form-templates.md](../customization/form-templates.md) ·
[../customization/ui-adapters.md](../customization/ui-adapters.md).

The default template renders `:standard`, `:wizard` and `:tabs` layouts; you only need your own
when the arrangement itself differs (a sidebar form, a two-pane editor).

## TODO
- [ ] `features` narrowed only where a feature must genuinely be off
- [ ] `debounce` set once here rather than repeated on every field
- [ ] `ui_adapter` is the app's adapter once components exist
- [ ] Theme classes set on the domain when every form shares them
- [ ] `theme.extra` keys read from the template module that consumes them

## DSL reference

Generated from the schema, always current:

- Resource — [`mishka_gervaz.form.presentation`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-presentation) · [`mishka_gervaz.form.presentation.theme`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-presentation-theme)

- Domain — [`mishka_gervaz.form`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-domain.html#mishka_gervaz-form) · [`mishka_gervaz.form.theme`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-domain.html#mishka_gervaz-form-theme)

**Schema:** `MishkaGervaz.Form.Dsl.Presentation`, `Form.Dsl.DomainDefaults` ·
**Behaviours:** `MishkaGervaz.Form.Behaviours.Template`, `MishkaGervaz.Behaviours.UIAdapter`

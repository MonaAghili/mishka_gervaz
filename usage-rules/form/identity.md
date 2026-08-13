# Form → `identity`

Names the form. The name **is** the LiveComponent id.

```elixir
identity do
  name :post_form
  route "/admin/dashboard/blog/posts"
  stream_name :post_form_stream
end
```

| Option | Type | Note |
|---|---|---|
| `name` | atom | derived as `<resource>_form` when omitted — declare it anyway |
| `route` | string | base path for the redirect after save |
| `stream_name` | atom | derived as `<name>_stream` |

## Mount with the derived id, never a literal

```elixir
<.live_component
  module={MishkaGervaz.Form.Web.Live}
  id={MishkaGervaz.Resource.Info.Form.component_id(MyApp.Blog.Post)}
  resource={MyApp.Blog.Post}
  current_user={@current_user}
/>
```

`component_id/1` returns `name` as a string. Using it means the id can never drift from the DSL —
and the id is what `send_update/2` and the upload namespacing both key on.

Uploads are namespaced with this id, which is why several forms may share one page without their
upload configs colliding.

## TODO
- [ ] `name` declared explicitly
- [ ] Mount uses `FormInfo.component_id(Resource)` rather than a hand-typed string
- [ ] `route` set if the form redirects after save

## DSL reference

Generated from the schema, always current:

- Resource — [`mishka_gervaz.form.identity`](https://hexdocs.pm/mishka_gervaz/dsl-mishkagervaz-resource.html#mishka_gervaz-form-identity)

**Schema:** `MishkaGervaz.Form.Dsl.Identity` · **Verifier:** `Form.Verifiers.ValidateIdentity`

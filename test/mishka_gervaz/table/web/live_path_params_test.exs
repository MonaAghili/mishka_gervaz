defmodule MishkaGervaz.Table.Web.LivePathParamsTest do
  @moduledoc """
  A path param that names an attribute is a filter, so changing one has to re-read.

  `QueryBuilder.apply_path_params/3` turns such a param into an `Ash.Query.filter/2` — which means a
  mount that swaps `%{category_id: a}` for `%{category_id: b}`, or drops the key to mean "all", has
  changed the query. Before, that branch of `update/2` returned `should_load?: false` unconditionally
  and left the reader looking at the rows the OLD value selected: a filter that appears not to work.

  Asserted against the source because the decision lives in a LiveComponent's `update/2`, which needs
  a mounted view and a live socket to exercise; what is pinned here is the rule, at the line that
  makes it.
  """
  use ExUnit.Case, async: true

  @source File.read!("lib/mishka_gervaz/table/web/live.ex")

  test "the params branch reloads when the params differ" do
    assert @source =~ "{state, path_params != existing_state.path_params}"
  end

  test "it no longer refuses to reload whatever arrived" do
    refute @source =~ "end)\n\n          {state, false}"
  end
end

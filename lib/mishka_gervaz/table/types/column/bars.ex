defmodule MishkaGervaz.Table.Types.Column.Bars do
  @moduledoc """
  Bar-gauge column type — renders a small numeric value (e.g. a `0..N` priority) as filled bars plus
  the number, so a resource declares the colour ramp instead of hand-rolling the bar markup.

  ## Options (via `column.ui.extra`)

    * `:max`     - number of bars (default `4`)
    * `:percent` - `true` when the value is a `0..100` percentage/weight (e.g. a runtime `priority`).
      Fills the bars in proportion to the value (`ceil(value / 100 * max)`) and colours by percentage
      band (`0–49` grey → `50–79` amber → `80–100` green) instead of the ordinal ramp — so a `54`
      reads as a mid-weight amber gauge, not a maxed-out red one.
    * `:ceiling` - explicit denominator for proportional fill; `:percent` is shorthand for `ceiling: 100`.
      Without either, the lit count is the ordinal `min(max, value + 1)` (so `0` still shows one bar).
    * `:scale`   - ordered `[{max_value_inclusive, hex} | {:default, hex}]`; the first entry whose
      threshold is `>=` the value wins, `{:default, hex}` is the catch-all. Overrides the ramp implied
      by `:percent`. Ordinal default: `[{0, "#a8a5a0"}, {1, "#1f9d6b"}, {2, "#cf8a24"}, {:default, "#e5484d"}]`.

  Delegates the markup to the adapter's `cell_bars/1`.

  Examples:

      column :priority do          # a 0..100 weight
        ui do
          type :bars
          extra %{max: 4, percent: true}
        end
      end

      column :signal do            # a small 0..3 ordinal
        ui do
          type :bars
          extra %{max: 4}
        end
      end

  See `MishkaGervaz.Table.Behaviours.ColumnType`, `MishkaGervaz.Table.Types.Column` (registry), and
  `MishkaGervaz.UIAdapters.Tailwind` (`cell_bars/1`).
  """

  @behaviour MishkaGervaz.Table.Behaviours.ColumnType

  @default_scale [{0, "#a8a5a0"}, {1, "#1f9d6b"}, {2, "#cf8a24"}, {:default, "#e5484d"}]
  @percent_scale [{49, "#a8a5a0"}, {79, "#cf8a24"}, {:default, "#1f9d6b"}]

  @impl true
  def render(value, column, _record, ui) do
    num = to_number(value)
    extra = get_extra(column)
    total = extra[:max] || 4
    percent? = extra[:percent] == true
    ceiling = extra[:ceiling] || (percent? && 100) || nil
    scale = extra[:scale] || (percent? && @percent_scale) || @default_scale

    color = pick_color(scale, num)
    filled = filled_bars(num, total, ceiling)

    ui.cell_bars(%{__changed__: %{}, value: num, filled: filled, max: total, color: color})
  end

  @spec filled_bars(integer(), pos_integer(), pos_integer() | nil) :: pos_integer()
  defp filled_bars(num, total, ceiling) when is_integer(ceiling) and ceiling > 0,
    do: (num / ceiling * total) |> ceil() |> max(1) |> min(total)

  defp filled_bars(num, total, _ceiling), do: min(total, max(1, num + 1))

  @spec pick_color([{integer() | :default, String.t()}], integer()) :: String.t()
  defp pick_color([{:default, hex} | _], _num), do: hex
  defp pick_color([{threshold, hex} | _], num) when num <= threshold, do: hex
  defp pick_color([_ | rest], num), do: pick_color(rest, num)
  defp pick_color([], _num), do: "#a8a5a0"

  @spec to_number(term()) :: integer()
  defp to_number(n) when is_integer(n), do: n
  defp to_number(n) when is_float(n), do: round(n)
  defp to_number(_), do: 0

  @spec get_extra(map()) :: map()
  defp get_extra(%{ui: %{extra: extra}}) when is_map(extra), do: extra
  defp get_extra(_), do: %{}
end

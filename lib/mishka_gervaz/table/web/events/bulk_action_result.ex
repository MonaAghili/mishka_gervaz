defmodule MishkaGervaz.Table.Web.Events.BulkActionResult do
  @moduledoc """
  Structured summary of a bulk action's outcome.

  Passed as the first argument to bulk lifecycle hooks
  (`:after_bulk_action`, `:on_bulk_action_success`, `:on_bulk_action_error`)
  so authors can read counts, records, and errors directly without parsing
  `Ash.BulkResult`. The raw bulk result is still available as `:ash_result`
  for power use.

  ## Fields

    * `:action_name` — the action name (atom, e.g. `:master_unarchive`).
    * `:action_type` — the action kind (`:destroy`, `:update`, `:unarchive`,
      `:soft_delete`, `:permanent_destroy`).
    * `:status` — overall outcome (`:success`, `:partial_success`, `:error`).
    * `:succeeded_count` — records that completed successfully.
    * `:failed_count` — records that errored during the bulk.
    * `:skipped_count` — records skipped **before** the bulk ran (currently
      only set by the unarchive conflict-skip path).
    * `:requested_count` — records originally selected; `nil` if the selection
      was `:all` and the total wasn't computed.
    * `:succeeded_records` — records returned by the bulk (may be `[]` if the
      action wasn't configured to return them).
    * `:failed_errors` — list of error structs from the bulk.
    * `:skipped_record_ids` — IDs of records skipped pre-execution.
    * `:ash_result` — the underlying `Ash.BulkResult` (escape hatch).

  ## Customization

  Like the sibling handlers in `events/`, the builder is overridable:

      defmodule MyApp.BulkActionResult do
        use MishkaGervaz.Table.Web.Events.BulkActionResult

        def build(action_name, action_type, result, opts) do
          summary = super(action_name, action_type, result, opts)
          %{summary | ash_result: nil}  # strip raw result for telemetry/logging
        end
      end

  See `MishkaGervaz.Table.Web.Events.BulkActionHooks` for the hook-author
  helpers; `MishkaGervaz.Table.Web.Events.BulkActionHandler` for the
  consumer.
  """

  @type status :: :success | :partial_success | :error

  @type t :: %__MODULE__{
          action_name: atom() | nil,
          action_type: atom() | nil,
          status: status() | nil,
          succeeded_count: non_neg_integer(),
          failed_count: non_neg_integer(),
          skipped_count: non_neg_integer(),
          requested_count: non_neg_integer() | nil,
          succeeded_records: list(),
          failed_errors: list(),
          skipped_record_ids: list(),
          ash_result: Ash.BulkResult.t() | nil
        }

  defstruct action_name: nil,
            action_type: nil,
            status: nil,
            succeeded_count: 0,
            failed_count: 0,
            skipped_count: 0,
            requested_count: nil,
            succeeded_records: [],
            failed_errors: [],
            skipped_record_ids: [],
            ash_result: nil

  @doc """
  Builds a summary from the raw `Ash.BulkResult`.

  Supported opts:

    * `:skipped_record_ids` — IDs filtered out before the bulk ran.
    * `:requested_count` — original selection size.
  """
  @callback build(
              action_name :: atom(),
              action_type :: atom(),
              result :: Ash.BulkResult.t(),
              opts :: keyword()
            ) :: t()

  @doc """
  Convenience entry point delegating to `__MODULE__.Default.build/4`.

  Direct callers (the handler, tests, ad-hoc helpers) use this; resources
  that need a custom builder swap the whole module via the DSL by
  `use MishkaGervaz.Table.Web.Events.BulkActionResult` and overriding
  `build/4`.
  """
  @spec build(atom(), atom(), Ash.BulkResult.t()) :: t()
  def build(action_name, action_type, result),
    do: build(action_name, action_type, result, [])

  @spec build(atom(), atom(), Ash.BulkResult.t(), keyword()) :: t()
  defdelegate build(action_name, action_type, result, opts),
    to: __MODULE__.Default

  defmacro __using__(_opts) do
    quote do
      @behaviour MishkaGervaz.Table.Web.Events.BulkActionResult

      alias MishkaGervaz.Table.Web.Events.BulkActionResult

      @impl true
      def build(action_name, action_type, %Ash.BulkResult{} = result, opts) do
        skipped_ids = Keyword.get(opts, :skipped_record_ids, [])
        requested = Keyword.get(opts, :requested_count)
        succeeded = result.records || []
        failed = result.errors || []

        %BulkActionResult{
          action_name: action_name,
          action_type: action_type,
          status: result.status,
          succeeded_count: length(succeeded),
          failed_count: length(failed),
          skipped_count: length(skipped_ids),
          requested_count: requested,
          succeeded_records: succeeded,
          failed_errors: failed,
          skipped_record_ids: skipped_ids,
          ash_result: result
        }
      end

      defoverridable build: 4
    end
  end
end

defmodule MishkaGervaz.Table.Web.Events.BulkActionResult.Default do
  @moduledoc false
  use MishkaGervaz.Table.Web.Events.BulkActionResult
end

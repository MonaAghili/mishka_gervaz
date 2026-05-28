defmodule MishkaGervaz.Table.Web.Events.BulkActionResultTest.CustomResult do
  @moduledoc false
  use MishkaGervaz.Table.Web.Events.BulkActionResult

  def build(action_name, action_type, result, opts) do
    summary = super(action_name, action_type, result, opts)
    %{summary | ash_result: :stripped}
  end
end

defmodule MishkaGervaz.Table.Web.Events.BulkActionResultTest do
  @moduledoc """
  Tests for the bulk action summary struct and its builder.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Table.Web.Events.BulkActionResult

  defp bulk_result(opts) do
    %Ash.BulkResult{
      status: Keyword.fetch!(opts, :status),
      records: Keyword.get(opts, :records, []),
      errors: Keyword.get(opts, :errors, [])
    }
  end

  describe "build/4 — counts and status" do
    test "full success maps record count and zero failures" do
      result = bulk_result(status: :success, records: [%{id: 1}, %{id: 2}])

      summary = BulkActionResult.build(:archive, :destroy, result)

      assert summary.status == :success
      assert summary.succeeded_count == 2
      assert summary.failed_count == 0
      assert summary.succeeded_records == [%{id: 1}, %{id: 2}]
      assert summary.failed_errors == []
    end

    test "partial success maps both succeeded and failed counts" do
      result = bulk_result(status: :partial_success, records: [%{id: 1}], errors: [:boom])

      summary = BulkActionResult.build(:activate, :update, result)

      assert summary.status == :partial_success
      assert summary.succeeded_count == 1
      assert summary.failed_count == 1
      assert summary.failed_errors == [:boom]
    end

    test "full error maps zero succeeded and the error count" do
      result = bulk_result(status: :error, records: [], errors: [:e1, :e2])

      summary = BulkActionResult.build(:destroy, :destroy, result)

      assert summary.status == :error
      assert summary.succeeded_count == 0
      assert summary.failed_count == 2
    end

    test "nil records and errors are treated as empty" do
      result = %Ash.BulkResult{status: :success, records: nil, errors: nil}

      summary = BulkActionResult.build(:archive, :destroy, result)

      assert summary.succeeded_count == 0
      assert summary.failed_count == 0
      assert summary.succeeded_records == []
      assert summary.failed_errors == []
    end
  end

  describe "build/4 — passthrough fields and opts" do
    test "carries action name and type" do
      result = bulk_result(status: :success, records: [])

      summary = BulkActionResult.build(:master_unarchive, :unarchive, result)

      assert summary.action_name == :master_unarchive
      assert summary.action_type == :unarchive
    end

    test "skipped_record_ids opt sets skipped count and ids" do
      result = bulk_result(status: :success, records: [%{id: 1}])

      summary =
        BulkActionResult.build(:unarchive, :unarchive, result,
          skipped_record_ids: ["a", "b", "c"]
        )

      assert summary.skipped_count == 3
      assert summary.skipped_record_ids == ["a", "b", "c"]
    end

    test "requested_count opt is stored" do
      result = bulk_result(status: :success, records: [])

      summary = BulkActionResult.build(:archive, :destroy, result, requested_count: 7)

      assert summary.requested_count == 7
    end

    test "defaults skipped to 0 and requested to nil when no opts" do
      result = bulk_result(status: :success, records: [%{id: 1}])

      summary = BulkActionResult.build(:archive, :destroy, result)

      assert summary.skipped_count == 0
      assert summary.skipped_record_ids == []
      assert summary.requested_count == nil
    end

    test "keeps the raw bulk result as an escape hatch" do
      result = bulk_result(status: :success, records: [%{id: 1}])

      summary = BulkActionResult.build(:archive, :destroy, result)

      assert summary.ash_result == result
    end
  end

  describe "override seam" do
    test "a custom builder can post-process the summary" do
      result = bulk_result(status: :success, records: [%{id: 1}])

      summary =
        MishkaGervaz.Table.Web.Events.BulkActionResultTest.CustomResult.build(
          :archive,
          :destroy,
          result,
          []
        )

      assert summary.succeeded_count == 1
      assert summary.ash_result == :stripped
    end
  end
end

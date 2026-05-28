defmodule MishkaGervaz.Table.Web.Events.BulkActionHooksTest.CustomHooks do
  @moduledoc false
  use MishkaGervaz.Table.Web.Events.BulkActionHooks

  def silence(socket) do
    send(self(), :silence_called)
    super(socket)
  end
end

defmodule MishkaGervaz.Table.Web.Events.BulkActionHooksTest do
  @moduledoc """
  Tests for the bulk action hook author helpers.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Table.Web.Events.BulkActionHooks

  defp socket, do: %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}

  describe "silence/1" do
    test "wraps the socket in a halt tuple" do
      s = socket()
      assert BulkActionHooks.silence(s) == {:halt, s}
    end
  end

  describe "use_default/1" do
    test "returns the socket unchanged" do
      s = socket()
      assert BulkActionHooks.use_default(s) == s
    end
  end

  describe "put_flash/3" do
    test "sends a put_flash message to the calling process and returns the socket" do
      s = socket()

      result = BulkActionHooks.put_flash(s, :info, "done")

      assert result == s
      assert_received {:put_flash, :info, "done"}
    end

    test "forwards the error kind" do
      BulkActionHooks.put_flash(socket(), :error, "nope")
      assert_received {:put_flash, :error, "nope"}
    end
  end

  describe "override seam" do
    test "a custom hooks module can wrap silence and still halt" do
      s = socket()

      assert MishkaGervaz.Table.Web.Events.BulkActionHooksTest.CustomHooks.silence(s) ==
               {:halt, s}

      assert_received :silence_called
    end
  end
end

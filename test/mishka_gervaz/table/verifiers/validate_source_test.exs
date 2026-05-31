defmodule MishkaGervaz.Verifiers.ValidateSourceTest do
  @moduledoc """
  Tests for the ValidateSource verifier.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Test.Resources.Post
  alias MishkaGervaz.Test.Resources.ArchivableResource
  alias MishkaGervaz.Test.Resources.ComplexTestResource
  alias MishkaGervaz.ResourceInfo

  describe "archive section validation" do
    test "valid archive section with AshArchival compiles successfully" do
      config = ResourceInfo.table_config(ArchivableResource)
      assert config.source.archive.enabled == true
    end

    test "archive section without AshArchival emits DslError warning" do
      unique_id = System.unique_integer([:positive])

      code = """
      defmodule MishkaGervaz.Test.ArchiveNoExt#{unique_id} do
        use Ash.Resource,
          domain: MishkaGervaz.Test.Domain,
          extensions: [MishkaGervaz.Resource],
          data_layer: Ash.DataLayer.Ets

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false, public?: true
        end

        actions do
          defaults [:read, :destroy, create: :*, update: :*]
          read :master_read
          read :tenant_read
        end

        mishka_gervaz do
          table do
            identity do
              name :archive_no_ext
              route "/admin/archive-no-ext"
            end

            source do
              archive do
                enabled true
              end
            end

            columns do
              column :name
            end
          end
        end
      end
      """

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_string(code)
        end)

      assert output =~ "archive section requires AshArchival.Resource extension"
      assert output =~ "Spark.Error.DslError"
    end

    test "no archive section without AshArchival compiles successfully" do
      config = ResourceInfo.table_config(Post)
      assert config.source.archive == nil
    end
  end

  describe "realtime prefix validation" do
    test "valid realtime with prefix compiles successfully" do
      config = ResourceInfo.table_config(ComplexTestResource)
      assert config.realtime.enabled == true
      assert config.realtime.prefix == "complex_posts"
    end

    test "realtime enabled without prefix emits DslError warning" do
      unique_id = System.unique_integer([:positive])

      code = """
      defmodule MishkaGervaz.Test.RealtimeNoPrefix#{unique_id} do
        use Ash.Resource,
          domain: MishkaGervaz.Test.Domain,
          extensions: [MishkaGervaz.Resource],
          data_layer: Ash.DataLayer.Ets

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false, public?: true
        end

        actions do
          defaults [:read, :destroy, create: :*, update: :*]
          read :master_read
          read :tenant_read
        end

        mishka_gervaz do
          table do
            identity do
              name :realtime_no_prefix
              route "/admin/realtime-no-prefix"
            end

            columns do
              column :name
            end

            realtime do
              enabled true
            end
          end
        end
      end
      """

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_string(code)
        end)

      assert output =~ "realtime prefix is required when enabled"
      assert output =~ "Spark.Error.DslError"
    end

    test "realtime enabled with empty prefix emits DslError warning" do
      unique_id = System.unique_integer([:positive])

      code = """
      defmodule MishkaGervaz.Test.RealtimeEmptyPrefix#{unique_id} do
        use Ash.Resource,
          domain: MishkaGervaz.Test.Domain,
          extensions: [MishkaGervaz.Resource],
          data_layer: Ash.DataLayer.Ets

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false, public?: true
        end

        actions do
          defaults [:read, :destroy, create: :*, update: :*]
          read :master_read
          read :tenant_read
        end

        mishka_gervaz do
          table do
            identity do
              name :realtime_empty_prefix
              route "/admin/realtime-empty-prefix"
            end

            columns do
              column :name
            end

            realtime do
              enabled true
              prefix ""
            end
          end
        end
      end
      """

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_string(code)
        end)

      assert output =~ "realtime prefix is required when enabled"
      assert output =~ "Spark.Error.DslError"
    end

    test "realtime disabled without prefix compiles successfully" do
      unique_id = System.unique_integer([:positive])
      module_name = "RealtimeDisabled#{unique_id}"

      code = """
      defmodule MishkaGervaz.Test.#{module_name} do
        use Ash.Resource,
          domain: MishkaGervaz.Test.Domain,
          extensions: [MishkaGervaz.Resource],
          data_layer: Ash.DataLayer.Ets

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false, public?: true
        end

        actions do
          defaults [:read, :destroy, create: :*, update: :*]
          read :master_read
          read :tenant_read
        end

        mishka_gervaz do
          table do
            identity do
              name :realtime_disabled
              route "/admin/realtime-disabled"
            end

            columns do
              column :name
            end

            realtime do
              enabled false
            end
          end
        end
      end
      """

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_string(code)
        end)

      refute output =~ "[MishkaGervaz.Test.#{module_name}]"
    end

    test "no realtime section compiles successfully" do
      config = ResourceInfo.table_config(Post)
      # Post has realtime enabled: false in source
      assert config.realtime != nil
    end
  end

  describe "feature-aware required actions (get/destroy)" do
    defp compile_stderr(code) do
      ExUnit.CaptureIO.capture_io(:stderr, fn -> Code.compile_string(code) end)
    end

    # A plain domain with NO gervaz default actions, so get/destroy are required
    # purely from the resource (isolates the feature-aware behavior from the
    # domain fallback that MishkaGervaz.Test.Domain provides).
    defp plain_domain(id), do: "MishkaGervaz.Test.PlainDomain#{id}"

    defp resource(id, name, source_actions, extra_table) do
      """
      defmodule #{plain_domain(id)} do
        use Ash.Domain, validate_config_inclusion?: false
      end

      defmodule MishkaGervaz.Test.#{name}#{id} do
        use Ash.Resource, domain: #{plain_domain(id)},
          extensions: [MishkaGervaz.Resource], data_layer: Ash.DataLayer.Ets

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false, public?: true
        end

        actions do
          defaults [:read, :destroy, create: :*, update: :*]
          read :master_read
          read :tenant_read
        end

        mishka_gervaz do
          table do
            identity do
              name :tbl_#{id}
              route "/admin/tbl-#{id}"
            end

            source do
              actions do
      #{source_actions}
              end
            end

            columns do
              column :name
            end
      #{extra_table}
          end
        end
      end
      """
    end

    test "a read-only table (no destructive/get feature) needs only read" do
      id = System.unique_integer([:positive])
      output = compile_stderr(resource(id, "ReadOnly", "read {:master_read, :tenant_read}", ""))

      refute output =~ "Missing required table source action"
    end

    test "a :destroy row action WITHOUT get/destroy fails at compile time, with reasons" do
      id = System.unique_integer([:positive])

      output =
        compile_stderr(
          resource(id, "NeedsDestroy", "read {:master_read, :tenant_read}", """
              row_actions do
                action :delete do
                  type :destroy
                end
              end
          """)
        )

      assert output =~ "Missing required table source action"
      assert output =~ ":get"
      assert output =~ ":destroy"
      assert output =~ "Spark.Error.DslError"
    end

    test "a :destroy row action WITH get + destroy declared compiles cleanly" do
      id = System.unique_integer([:positive])

      actions = """
      read {:master_read, :tenant_read}
                get {:master_read, :tenant_read}
                destroy {:destroy, :destroy}
      """

      output =
        compile_stderr(
          resource(id, "HasDestroy", actions, """
              row_actions do
                action :delete do
                  type :destroy
                end
              end
          """)
        )

      refute output =~ "Missing required table source action"
    end
  end
end

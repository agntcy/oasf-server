# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.ApplicationTest do
  use ExUnit.Case, async: true

  alias Schema.Application

  describe "parse_extensions/1" do
    test "returns no extensions when unset" do
      assert Application.parse_extensions(nil) == []
    end

    test "returns no extensions when blank" do
      assert Application.parse_extensions("") == []
      assert Application.parse_extensions("   ") == []
      assert Application.parse_extensions(" , ,") == []
    end

    test "splits and trims a comma-separated list" do
      assert Application.parse_extensions("extensions") == ["extensions"]

      assert Application.parse_extensions(" extensions , /abs/ext,,") == [
               "extensions",
               "/abs/ext"
             ]
    end
  end

  describe "check_schema_dir/1" do
    @describetag :tmp_dir

    test "accepts a directory with a version.json", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "version.json"), ~s({"version": "1.0.0"}))

      assert Application.check_schema_dir(dir) == :ok
    end

    test "rejects a directory without a version.json", %{tmp_dir: dir} do
      assert {:error, message} = Application.check_schema_dir(dir)
      assert message =~ "No schema found in SCHEMA_DIR=#{dir}"
    end

    test "rejects a missing directory", %{tmp_dir: dir} do
      assert {:error, _} = Application.check_schema_dir(Path.join(dir, "missing"))
    end

    test "rejects an unset SCHEMA_DIR" do
      assert {:error, "SCHEMA_DIR is not set" <> _} = Application.check_schema_dir(nil)
      assert {:error, "SCHEMA_DIR is not set" <> _} = Application.check_schema_dir("")
    end
  end
end

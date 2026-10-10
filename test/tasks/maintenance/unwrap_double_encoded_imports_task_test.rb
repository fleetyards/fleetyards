# frozen_string_literal: true

require "test_helper"

module Maintenance
  class UnwrapDoubleEncodedImportsTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::UnwrapDoubleEncodedImportsTask.new
      @user = create(:user)
    end

    def run_task
      @task.collection.each { @task.process(it) }
    end

    def double_encoded_sync(input:, output:)
      Imports::HangarSync.create!(user: @user, input: input.to_json, output: output.to_json)
    end

    test "unwraps the input and output a legacy sync stored as JSON strings" do
      vehicle = create(:vehicle, user: @user, name: "Pathfinder")
      import = double_encoded_sync(
        input: [{"name" => "Carrack", "type" => "ship"}],
        output: {"imported_vehicles" => [vehicle.id], "missing_models" => ["Idris"]}
      )
      assert_kind_of String, import.reload.output

      run_task
      import.reload

      assert_equal [{"name" => "Carrack", "type" => "ship"}], import.input
      assert_equal({imported: ["Pathfinder"], missing: ["Idris"]}, import.result_details)
    end

    test "leaves a stored \"null\" string, a malformed one and well-formed rows alone" do
      null_import = Imports::HangarSync.create!(user: @user, input: "null")
      malformed = Imports::HangarSync.create!(user: @user, input: '[{"name":"Carr')
      current = Imports::HangarSync.create!(user: @user, input: [{"type" => "ship"}], output: {"imported_vehicles" => []})

      assert_equal [], @task.collection.flat_map { it.pluck(:id) }

      run_task

      assert_equal "null", null_import.reload.input
      assert_equal '[{"name":"Carr', malformed.reload.input
      assert_equal({"imported_vehicles" => []}, current.reload.output)
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Maintenance
  class BackfillHardpointBuildsTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::BackfillHardpointBuildsTask.new
      @source = ScData::Source.current
    end

    test "#collection is the game-file slots and not the matrix ones" do
      game_files = create(:hardpoint, source: :game_files)
      matrix = create(:hardpoint, source: :ship_matrix)

      ids = @task.collection.pluck(:id)

      assert_includes ids, game_files.id
      assert_not_includes ids, matrix.id
    end

    test "#process writes what the slot says into a row for the source in force" do
      component = create(:component)
      hardpoint = create(:hardpoint,
        source: :game_files, component:, min_size: 2, max_size: 4,
        types: ["MissileLauncher"], port_tags: ["Eclipse_BombRack"],
        required_tags: ["Eclipse_BombRack"], flags: ["editable"])

      @task.process(hardpoint)

      build = hardpoint.builds.sole
      assert_equal @source.environment, build.environment
      assert_equal @source.version, build.version
      assert_equal component.id, build.component_id
      assert_equal 2, build.min_size
      assert_equal 4, build.max_size
      assert_equal ["MissileLauncher"], build.types
      assert_equal ["Eclipse_BombRack"], build.port_tags
      assert_equal ["Eclipse_BombRack"], build.required_tags
      assert_equal ["editable"], build.flags
    end

    # The three columns Hardpoint derives from the installed component in a
    # `before_validation`. They have to survive the trip as the same enum value,
    # which is what the shared constant on Hardpoint is for.
    test "#process carries the derived group and category across as themselves" do
      hardpoint = create(:hardpoint, source: :game_files,
        component: create(:component, category: "weapons"))

      @task.process(hardpoint)

      build = hardpoint.builds.sole
      assert_equal hardpoint.group, build.group
      assert_equal hardpoint.category, build.category
      assert_equal hardpoint.group_key, build.group_key
    end

    # Additive and re-runnable: the row for a source is updated in place rather
    # than a second one landing beside it.
    test "#process is idempotent for the same source" do
      hardpoint = create(:hardpoint, source: :game_files, min_size: 2)

      @task.process(hardpoint)
      @task.process(hardpoint)

      assert_equal 1, hardpoint.builds.count
    end

    test "#process picks up a slot whose facts changed since the last run" do
      hardpoint = create(:hardpoint, source: :game_files, min_size: 2)
      @task.process(hardpoint)

      hardpoint.update!(min_size: 5, max_size: 5)
      @task.process(hardpoint)

      assert_equal 5, hardpoint.builds.sole.min_size
    end

    # Another environment's row is a separate row, not a rewrite of this one --
    # the whole point of the table.
    test "#process leaves another environment's row alone" do
      hardpoint = create(:hardpoint, source: :game_files, min_size: 2)
      other = create(:hardpoint_build, hardpoint:, environment: "ptu",
        version: "9.9.9-ptu.1", min_size: 7)

      @task.process(hardpoint)

      assert_equal 2, hardpoint.builds.count
      assert_equal 7, other.reload.min_size
    end
  end
end

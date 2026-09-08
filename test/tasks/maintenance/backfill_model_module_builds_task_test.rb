# frozen_string_literal: true

require "test_helper"

module Maintenance
  class BackfillModelModuleBuildsTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::BackfillModelModuleBuildsTask.new
      @source = ScData::Source.current
    end

    # Only keyed modules: the loader walks no others, so no build has an opinion
    # about them and `in_build` leaves them alone by the same rule.
    test "#collection is the keyed modules and not the store-only ones" do
      keyed = create(:model_module, sc_key: "keyed")
      store_only = create(:model_module, sc_key: nil)

      ids = @task.collection.pluck(:id)

      assert_includes ids, keyed.id
      assert_not_includes ids, store_only.id
    end

    test "#process writes what the module says into a row for the source in force" do
      model_module = create(:model_module, sc_key: "keyed", description: "a cargo bay")

      @task.process(model_module)

      build_row = model_module.builds.sole
      assert_equal @source.environment, build_row.environment
      assert_equal @source.version, build_row.version
      assert_equal "a cargo bay", build_row.description
    end

    test "#process is idempotent for the same source" do
      model_module = create(:model_module, sc_key: "keyed", description: "a cargo bay")

      @task.process(model_module)
      @task.process(model_module)

      assert_equal 1, model_module.builds.count
    end

    test "#process leaves another environment's row alone" do
      model_module = create(:model_module, sc_key: "keyed")
      other = create(:model_module_build, model_module:, environment: "ptu",
        version: "9.9.9-ptu.1", description: "what ptu says")

      @task.process(model_module)

      assert_equal 2, model_module.builds.count
      assert_equal "what ptu says", other.reload.description
    end
  end
end

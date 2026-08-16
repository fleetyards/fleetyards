# frozen_string_literal: true

require "test_helper"

module Cleanup
  class ComponentVersionsJobTest < ActiveJob::TestCase
    setup do
      Component.delete_all
      @version = Rails.configuration.sc_data[:version]
      @current = create(:component, name: "FR-66 Shield", sc_key: "fr66", version: @version)
      @stale = create(:component, name: "FR-66 Shield", sc_key: "fr66", version: "0.0.1-live.1")
    end

    test "#perform takes the components older builds left behind" do
      result = ::Cleanup::ComponentVersionsJob.new.perform

      assert_equal [@current.id], Component.pluck(:id)
      assert_equal 1, result.removed
    end

    # The reference is what keeps a saved loadout meaning what its owner chose,
    # and the foreign key would refuse the delete anyway.
    test "#perform keeps a component a saved loadout still points at" do
      create(:vehicle_loadout_hardpoint, component: @stale)

      result = ::Cleanup::ComponentVersionsJob.new.perform

      assert Component.exists?(@stale.id)
      assert_equal 0, result.removed
      assert_equal 1, result.kept_for_loadouts
    end

    # Nothing else clears this one: it carries a component_id with no foreign
    # key and no association back from Component.
    test "#perform clears the component off a model hardpoint loadout" do
      loadout = create(:model_hardpoint_loadout, component: @stale)

      ::Cleanup::ComponentVersionsJob.new.perform

      assert_nil loadout.reload.component_id
    end

    # Every row looks stale before the current build has been imported, so the
    # guard is the difference between a cleanup and an empty table.
    test "#perform does nothing until the current build has been imported" do
      Component.where(version: @version).delete_all

      ::Cleanup::ComponentVersionsJob.new.perform

      assert Component.exists?(@stale.id)
    end

    test "#perform leaves the current build alone when there is nothing stale" do
      Component.where.not(version: @version).delete_all

      result = ::Cleanup::ComponentVersionsJob.new.perform

      assert_equal [@current.id], Component.pluck(:id)
      assert_equal 0, result.removed
    end

    test "#perform takes the sub-hardpoints a stale component owns with it" do
      hardpoint = create(:hardpoint, parent: @stale)

      ::Cleanup::ComponentVersionsJob.new.perform

      assert_not Hardpoint.exists?(hardpoint.id)
    end
  end
end

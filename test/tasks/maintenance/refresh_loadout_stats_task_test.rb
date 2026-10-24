# frozen_string_literal: true

require "test_helper"

module Maintenance
  class RefreshLoadoutStatsTaskTest < ActiveSupport::TestCase
    test "writes the guns of every ship for each source a reader can pick" do
      model = create(:model)
      create(:hardpoint, parent: model, sc_name: "hardpoint_gun_nose", source: :game_files, types: %w[WeaponGun],
        min_size: 2, max_size: 2, component: create(:component, component_type: "WeaponGun", category: "weapons", size: "2"))
      task = RefreshLoadoutStatsTask.new

      assert_not_empty task.collection
      task.collection.each { task.process(it) }

      assert_equal(
        task.collection.map { |source| [source.environment, 2] }.sort,
        LoadoutStat.where(fitting: model).pluck(:environment, :max_weapon_size).sort
      )
    end
  end
end

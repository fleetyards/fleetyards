# frozen_string_literal: true

require "test_helper"

class ModelPositionTest < ActiveSupport::TestCase
  test ".generate_for_model! adds a gunner for a manned turret" do
    model = create(:model)
    turret = create(:component, name: "Manned Turret", component_type: "TurretBase")
    create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_turret_top", component: turret)

    ModelPosition.generate_for_model!(model)

    assert_equal ["turret_gunner"], model.model_positions.reload.pluck(:position_type)
  end

  test ".generate_for_model! ignores a turret that is not manned" do
    model = create(:model)
    turret = create(:component, name: "Remote Turret", component_type: "TurretBase")
    create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_turret_remote", component: turret)

    ModelPosition.generate_for_model!(model)

    assert_empty model.model_positions.reload
  end
end

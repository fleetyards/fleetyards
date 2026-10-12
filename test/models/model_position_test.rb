# frozen_string_literal: true

require "test_helper"

class ModelPositionTest < ActiveSupport::TestCase
  def seat
    @seat ||= create(:component, category: "seat")
  end

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

  # Mission and fleet-event slots point at these rows, so a reload must not
  # hand them new ids.
  test ".generate_for_model! keeps the ids of seats the build still has" do
    model = create(:model)
    create(:hardpoint, parent: model, source: :game_files, component: seat, sc_name: "hardpoint_seat_pilot")
    ModelPosition.generate_for_model!(model)
    pilot = model.model_positions.sole
    slot = create(:mission_slot, model_position: pilot)

    ModelPosition.generate_for_model!(model)

    assert_equal [pilot.id], model.model_positions.reload.pluck(:id)
    assert_equal pilot.id, slot.reload.model_position_id
  end

  test ".generate_for_model! drops a seat the build lost and unlinks its slots" do
    model = create(:model)
    gunner = create(:hardpoint, parent: model, source: :game_files, component: seat, sc_name: "hardpoint_seat_gunner")
    ModelPosition.generate_for_model!(model)
    slot = create(:fleet_event_slot, model_position: model.model_positions.sole)
    HardpointBuild.where(hardpoint: gunner).delete_all
    create(:hardpoint_build, hardpoint: create(:hardpoint, :without_build, parent: model, source: :game_files))

    ModelPosition.generate_for_model!(model)

    assert_empty model.model_positions.reload
    assert_nil slot.reload.model_position_id
  end

  test ".generate_for_model! leaves a seat an admin curated alone" do
    model = create(:model)
    pilot = create(:hardpoint, parent: model, source: :game_files, component: seat, sc_name: "hardpoint_seat_pilot")
    curated = create(:model_position, model:, hardpoint: pilot, source: :curated, name: "Captain", position_type: :pilot)

    ModelPosition.generate_for_model!(model)

    assert_equal [curated.id], model.model_positions.reload.pluck(:id)
  end

  def two_environments
    Rails.configuration.stubs(:sc_data).returns({sources: {live: "3.24.0", ptu: "3.24.1-ptu.2"}, default: "live"})
    [ScData::Source.find(:live), ScData::Source.find(:ptu)]
  end

  def seat_in(model, sc_name, *sources)
    create(:hardpoint, :without_build, parent: model, source: :game_files, component: seat, sc_name:).tap do |hardpoint|
      sources.each { |source| create(:hardpoint_build, hardpoint:, environment: source.environment, version: source.version) }
    end
  end

  # Each environment sees the seats its build has, from rows both share.
  test ".in_build gives each environment the seats its build carries" do
    live, ptu = two_environments
    model = create(:model)
    pilot = seat_in(model, "hardpoint_seat_pilot", live, ptu)
    gunner = seat_in(model, "hardpoint_seat_gunner", ptu)

    ScData::Source.with(live) { ModelPosition.generate_for_model!(model) }
    ScData::Source.with(ptu) { ModelPosition.generate_for_model!(model) }

    assert_equal [pilot.id], model.model_positions.in_build(live).pluck(:hardpoint_id)
    assert_equal [pilot.id, gunner.id].sort, model.model_positions.in_build(ptu).pluck(:hardpoint_id).sort
  end

  # A load writes its own build. Removing what only the other one carries would
  # flip the seats every time the two loads take turns.
  test ".generate_for_model! keeps a seat only another build carries" do
    live, ptu = two_environments
    model = create(:model)
    seat_in(model, "hardpoint_seat_pilot", live, ptu)
    gunner = seat_in(model, "hardpoint_seat_gunner", ptu)
    ScData::Source.with(ptu) { ModelPosition.generate_for_model!(model) }
    kept = model.model_positions.find_by!(hardpoint: gunner)

    ScData::Source.with(live) { ModelPosition.generate_for_model!(model) }

    assert ModelPosition.exists?(kept.id)
  end

  test ".generate_for_model! counts the default build for curation" do
    live, ptu = two_environments
    model = create(:model, crew: 2)
    seat_in(model, "hardpoint_seat_pilot", live, ptu)
    seat_in(model, "hardpoint_seat_gunner", ptu)

    ScData::Source.with(ptu) { ModelPosition.generate_for_model!(model) }

    assert_predicate model.reload, :positions_need_curation?
  end
end

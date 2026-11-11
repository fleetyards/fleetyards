# frozen_string_literal: true

require "test_helper"

class MissionTeams::CopierTest < ActiveSupport::TestCase
  setup do
    @mission = create(:mission)
    @source = create(:mission_team, mission: @mission)
    create(:mission_slot, slottable: @source, title: "Lead", position: 0)
    @listed = build(:mission_ship, mission_team: @source, classification: nil, position: 0)
    @first_model = create(:model, :in_game)
    @second_model = create(:model, :in_game)
    @listed.mission_ship_models.build(model: @first_model, position: 0)
    @listed.mission_ship_models.build(model: @second_model, position: 1)
    @listed.save!
    create(:mission_slot, slottable: @listed, title: "Gunner", position: 0)
  end

  test "copies slots, ships, allowed models and ship slots into an event team with their sources" do
    event_team = create(:fleet_event_team, fleet_event: create(:fleet_event, fleet: @mission.fleet))

    MissionTeams::Copier.new(@source, event_team).copy!

    assert_equal ["Lead"], event_team.fleet_event_slots.map(&:title)
    assert_equal [@source.mission_slots.first.id], event_team.fleet_event_slots.map(&:source_slot_id)
    ship = event_team.fleet_event_ships.sole
    assert_equal @listed.id, ship.source_ship_id
    assert_equal [@first_model.id, @second_model.id], ship.fleet_event_ship_models.map(&:model_id)
    assert_equal ["Gunner"], ship.fleet_event_slots.map(&:title)
  end

  test "appends after what a template team already holds" do
    target = create(:mission_team, mission: create(:mission, fleet: @mission.fleet))
    create(:mission_slot, slottable: target, title: "Typed", position: 0)
    create(:mission_ship, mission_team: target, position: 0)

    MissionTeams::Copier.new(@source, target).copy!

    assert_equal %w[Typed Lead], target.mission_slots.reload.map(&:title)
    assert_equal [0, 1], target.mission_ships.reload.map(&:position)
  end
  test "drops a listed ship that changed hands instead of failing the copy" do
    member = create(:user)
    fleet = @mission.fleet
    create(:fleet_membership, :accepted, fleet:, user: member)
    row = create(:fleet_squadron_membership, fleet_squadron: create(:fleet_squadron, fleet:),
      fleet_membership: fleet.fleet_memberships.find_by!(user: member))
    vehicle = create(:vehicle, user: member)
    candidate = @source.mission_slots.first.mission_slot_candidates.create!(fleet_squadron_membership: row, vehicle:)
    vehicle.update_columns(user_id: create(:user).id)
    event_team = create(:fleet_event_team, fleet_event: create(:fleet_event, fleet:))

    MissionTeams::Copier.new(MissionTeams::Copier.preload(MissionTeam.where(id: @source.id)).first, event_team).copy!

    copied = event_team.fleet_event_slots.first.fleet_event_slot_candidates.sole
    assert_equal candidate.fleet_squadron_membership_id, copied.fleet_squadron_membership_id
    assert_nil copied.vehicle_id
  end
end

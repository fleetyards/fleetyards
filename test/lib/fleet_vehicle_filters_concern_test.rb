# frozen_string_literal: true

require "test_helper"

class FleetVehicleFiltersConcernTest < ActiveSupport::TestCase
  class Filters
    include FleetVehicleFiltersConcern

    attr_reader :params

    def initialize(params)
      @params = ActionController::Parameters.new(params)
    end

    def squadron_vehicles(fleet) = for_squadron_vehicles(fleet)
  end

  setup do
    @member = create(:user)
    @fleet = create(:fleet, members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @row = create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.find_by!(user: @member))
    @first = create(:vehicle, user: @member)
    @second = create(:vehicle, user: @member)
  end

  def squadron_vehicle_ids(filters = Filters.new(q: {squadron_slug_in: [@squadron.slug]}))
    Vehicle.where(id: filters.squadron_vehicles(@fleet)).ids.sort
  end

  test "a second read of the squadron filter still narrows to the squadron" do
    filters = Filters.new(q: {squadron_slug_in: [@squadron.slug]})

    assert_equal [@first.id, @second.id].sort, squadron_vehicle_ids(filters)
    assert_equal [@first.id, @second.id].sort, squadron_vehicle_ids(filters)
  end

  test "a squadron nobody is in narrows to nothing, however often it is read" do
    empty = create(:fleet_squadron, fleet: @fleet)
    filters = Filters.new(q: {squadron_slug_in: [empty.slug]})

    assert_empty squadron_vehicle_ids(filters)
    assert_empty squadron_vehicle_ids(filters)
  end

  test "no squadron named leaves the scope alone" do
    assert_nil Filters.new(q: {}).squadron_vehicles(@fleet)
  end

  test "a member who picks ships gives the squadron only those and their loaners" do
    loaner = create(:vehicle, :loaner, user: @member, vehicle_id: @first.id)
    @row.update!(ships_filter: :picked)
    @row.fleet_squadron_membership_vehicles.create!(vehicle: @first)

    assert_equal [@first.id, loaner.id].sort, squadron_vehicle_ids
  end

  test "a member who picks nothing gives the squadron nothing" do
    @row.update!(ships_filter: :picked)

    assert_empty squadron_vehicle_ids
  end

  test "a hangar group gives the squadron the group plus what was picked on top" do
    group = create(:hangar_group, user: @member)
    third = create(:vehicle, user: @member)
    TaskForce.create!(hangar_group: group, vehicle: @first)
    @row.update!(ships_filter: :hangar_group, hangar_group: group)
    @row.fleet_squadron_membership_vehicles.create!(vehicle: third)

    assert_equal [@first.id, third.id].sort, squadron_vehicle_ids
  end

  test "another fleet's squadron of the same name reaches nothing here" do
    other = create(:fleet, members: [@member])
    create(:fleet_squadron, fleet: other, name: @squadron.name)
    filters = Filters.new(q: {squadron_slug_in: [@squadron.slug]})

    assert_equal [@first.id, @second.id].sort, Vehicle.where(id: filters.squadron_vehicles(@fleet)).ids.sort
  end
end

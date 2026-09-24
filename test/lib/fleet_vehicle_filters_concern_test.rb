# frozen_string_literal: true

require "test_helper"

class FleetVehicleFiltersConcernTest < ActiveSupport::TestCase
  class Filters
    include FleetVehicleFiltersConcern

    attr_reader :params

    def initialize(params)
      @params = ActionController::Parameters.new(params)
    end

    def squadron_user_ids(fleet) = for_squadrons(fleet)
  end

  setup do
    @member = create(:user)
    @fleet = create(:fleet, members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.find_by!(user: @member))
  end

  test "a second read of the squadron filter still narrows to the squadron" do
    filters = Filters.new(q: {squadron_slug_in: [@squadron.slug]})

    assert_equal [@member.id], filters.squadron_user_ids(@fleet)
    assert_equal [@member.id], filters.squadron_user_ids(@fleet)
  end

  test "a squadron nobody is in narrows to nobody, however often it is read" do
    empty = create(:fleet_squadron, fleet: @fleet)
    filters = Filters.new(q: {squadron_slug_in: [empty.slug]})

    assert_equal [], filters.squadron_user_ids(@fleet)
    assert_equal [], filters.squadron_user_ids(@fleet)
  end

  test "no squadron named leaves the scope alone" do
    assert_nil Filters.new(q: {}).squadron_user_ids(@fleet)
  end
end

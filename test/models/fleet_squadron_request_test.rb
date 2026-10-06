# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_requests
#
#  id                  :uuid             not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_membership_id :uuid             not null
#  fleet_squadron_id   :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_requests_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_requests_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#
require "test_helper"

class FleetSquadronRequestTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = create(:fleet_membership, :accepted, fleet: @fleet)
  end

  test "rejects a member of another fleet" do
    request = build(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: create(:fleet_membership, :accepted))

    refute request.valid?
    assert request.errors.of_kind?(:fleet_membership, :not_a_member)
  end

  test "rejects a member who is still only invited" do
    request = build(:fleet_squadron_request, fleet_squadron: @squadron,
      fleet_membership: create(:fleet_membership, :invited, fleet: @fleet))

    refute request.valid?
    assert request.errors.of_kind?(:fleet_membership, :not_a_member)
  end

  test "rejects a request for a team" do
    request = build(:fleet_squadron_request, fleet_squadron: create(:fleet_squadron, fleet: @fleet, team: true),
      fleet_membership: @membership)

    refute request.valid?
    assert request.errors.of_kind?(:fleet_squadron, :team)
  end

  test "rejects somebody already in the squadron" do
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
    request = build(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership)

    refute request.valid?
    assert request.errors.of_kind?(:fleet_squadron, :already_a_member)
  end

  test "rejects somebody in another squadron but not somebody on a team" do
    create(:fleet_squadron_membership, fleet_squadron: create(:fleet_squadron, fleet: @fleet, team: true), fleet_membership: @membership)

    assert build(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership).valid?

    create(:fleet_squadron_membership, fleet_squadron: create(:fleet_squadron, fleet: @fleet), fleet_membership: @membership)
    request = build(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership)

    refute request.valid?
    assert request.errors.of_kind?(:fleet_squadron, :exclusive_conflict)
  end

  test "accept! adds the member at the default rank and closes the request" do
    request = create(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership)

    row = request.accept!

    assert_equal "member", row.fleet_squadron_role.key
    refute FleetSquadronRequest.exists?(request.id)
  end

  test "adding somebody directly closes their request" do
    request = create(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership)

    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    refute FleetSquadronRequest.exists?(request.id)
  end

end

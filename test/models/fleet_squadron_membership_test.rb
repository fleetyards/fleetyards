# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_squadron_memberships
#
#  id                  :uuid             not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_membership_id :uuid             not null
#  fleet_squadron_id   :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_memberships_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_memberships_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#
class FleetSquadronMembershipTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = create(:fleet_membership, :accepted, fleet: @fleet)
  end

  test "rejects a member of another fleet" do
    outsider = create(:fleet_membership, :accepted, fleet: create(:fleet))
    row = build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: outsider)

    assert_not row.valid?
    assert_includes row.errors.attribute_names, :fleet_membership
  end

  test "rejects the same member twice in one squadron" do
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
    duplicate = build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :fleet_membership_id
  end

  # A member belongs to one squadron and to any number of teams. The rule
  # itself is `FleetSquadronTest::ExclusivityTest`; this is the shape of the
  # roster it leaves behind.
  test "allows one member on several teams of the same fleet" do
    other = create(:fleet_squadron, fleet: @fleet, team: true)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    assert_predicate build(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: @membership), :valid?
  end
end

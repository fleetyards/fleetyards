# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_roles
#
#  id              :uuid             not null, primary key
#  name            :string
#  permanent       :boolean
#  rank            :text
#  resource_access :text
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  discord_role_id :string
#  fleet_id        :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id_and_rank  (fleet_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
require "test_helper"

class FleetRoleTest < ActiveSupport::TestCase
  should belong_to(:fleet)

  setup do
    @member_user = create(:user)
    @fleet = create(:fleet, members: [@member_user])
    @member_role = @fleet.fleet_roles.ranked.last
    @officer_role = @fleet.fleet_roles.ranked.second
  end

  test "#destroy is refused while members are still assigned to the role" do
    refute @member_role.destroy

    assert_includes @member_role.errors[:base],
      I18n.t("activerecord.errors.models.fleet_role.attributes.base.cannot_destroy_with_members")
    assert FleetRole.exists?(@member_role.id)
    assert_equal @member_role, @fleet.fleet_memberships.find_by(user: @member_user).reload.fleet_role
  end

  test "#destroy! raises while members are still assigned to the role" do
    assert_raises ActiveRecord::RecordNotDestroyed do
      @member_role.destroy!
    end
  end

  test "#destroy succeeds for a role nobody is assigned to" do
    assert @officer_role.destroy
    refute FleetRole.exists?(@officer_role.id)
  end

  test "#destroy succeeds when only discarded memberships are assigned to the role" do
    membership = @fleet.fleet_memberships.find_by(user: @member_user)
    membership.discard

    assert @member_role.destroy
    assert_nil membership.reload.fleet_role_id
  end

  test "#destroy of the fleet still cascades through roles in use" do
    assert @fleet.destroy

    refute Fleet.exists?(@fleet.id)
    assert_empty FleetRole.where(fleet_id: @fleet.id)
    assert_empty FleetMembership.where(fleet_id: @fleet.id)
  end
end

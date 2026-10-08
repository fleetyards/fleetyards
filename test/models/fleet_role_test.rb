# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_roles
#
#  id                 :uuid             not null, primary key
#  name               :string
#  new_member_default :boolean          default(FALSE), not null
#  permanent          :boolean
#  rank               :text
#  resource_access    :text
#  slug               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  discord_role_id    :string
#  fleet_id           :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id_and_rank      (fleet_id,rank) UNIQUE
#  index_fleet_roles_on_one_default_per_fleet  (fleet_id) UNIQUE WHERE new_member_default
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

  test "a Discord role must be a Discord id" do
    @member_role.discord_role_id = "Officers"

    assert_not @member_role.valid?
    assert @member_role.errors.of_kind?(:discord_role_id, :invalid)
  end

  test "a Discord role cannot be @everyone" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "100000000000000001")
    @member_role.discord_role_id = "100000000000000001"

    assert_not @member_role.valid?
    assert_includes @member_role.errors.details[:discord_role_id], {error: :everyone_role}
  end

  test "a blank Discord role clears the mapping" do
    @member_role.update!(discord_role_id: " 300000000000000001 ")
    assert_equal "300000000000000001", @member_role.discord_role_id

    @member_role.update!(discord_role_id: "")
    assert_nil @member_role.discord_role_id
  end

  test "ranks sort by byte, not by the database collation" do
    upper = create(:fleet_role, fleet: @fleet, name: "Upper", rank: "B")
    lower = create(:fleet_role, fleet: @fleet, name: "Lower", rank: "a")

    assert_equal [upper, lower], @fleet.fleet_roles.ranked.last(2)
  end

  test "#destroy is refused while members are still assigned to the role" do
    @officer_role.make_default!

    refute @member_role.destroy

    assert_includes @member_role.errors[:base],
      I18n.t("activerecord.errors.models.fleet_role.attributes.base.cannot_destroy_with_members")
    assert FleetRole.exists?(@member_role.id)
    assert_equal @member_role, @fleet.fleet_memberships.find_by(user: @member_user).reload.fleet_role
  end

  test "#destroy! raises while members are still assigned to the role" do
    @officer_role.make_default!

    assert_raises ActiveRecord::RecordNotDestroyed do
      @member_role.destroy!
    end
  end

  test "#destroy succeeds for a role nobody is assigned to" do
    assert @officer_role.destroy
    refute FleetRole.exists?(@officer_role.id)
  end

  test "#destroy succeeds when only discarded memberships are assigned to the role" do
    @officer_role.make_default!
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

  test "seeds Member as the one default role" do
    assert_equal [@member_role], @fleet.fleet_roles.where(new_member_default: true).to_a
    assert_equal @member_role, @fleet.default_member_role
  end

  test "#destroy is refused for the default role" do
    @fleet.fleet_memberships.find_by(user: @member_user).discard

    refute @member_role.destroy
    assert_includes @member_role.errors[:base],
      I18n.t("activerecord.errors.models.fleet_role.attributes.base.cannot_destroy_default")
  end

  test "the default moves and is never simply cleared" do
    refute @member_role.update(new_member_default: false)
    assert_includes @member_role.errors.details[:new_member_default], {error: :required}

    @officer_role.make_default!

    assert_equal [@officer_role], @fleet.fleet_roles.where(new_member_default: true).to_a
    assert_equal @officer_role, @fleet.reload.default_member_role
  end

  test "the Admin role cannot be the default" do
    admin_role = @fleet.fleet_roles.ranked.first

    assert_raises(ActiveRecord::RecordInvalid) { admin_role.make_default! }
    assert_equal [@member_role], @fleet.fleet_roles.where(new_member_default: true).to_a
  end

  # Promote and demote key on the slug, so a rename must not move it.
  test "a rename keeps the slug" do
    @member_role.update!(name: "Recruit")

    assert_equal "member", @member_role.reload.slug
  end

  test "a fleet with no default marked still hands out its lowest role" do
    FleetRole.where(fleet: @fleet).update_all(new_member_default: false)

    assert_equal @member_role, @fleet.reload.default_member_role
  end

  test "the fallback never hands a new member the Admin role" do
    FleetRole.where(fleet: @fleet).update_all(new_member_default: false)
    FleetRole.where(fleet: @fleet).where.not(permanent: true).update_all(rank: nil)

    assert_not @fleet.reload.default_member_role&.permanent?
  end
end

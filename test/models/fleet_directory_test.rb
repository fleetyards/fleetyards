# frozen_string_literal: true

require "test_helper"

class FleetDirectoryTest < ActiveSupport::TestCase
  # The creator is the first accepted member.
  def listed_fleet(sid: "TEST", members: 2, **attributes)
    fleet = create(:fleet, rsi_sid: sid, created_by: create(:user).id, members: create_list(:user, members - 1), **attributes)
    fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: sid, rsi_verification_status: :verified)
    fleet
  end

  test "a verified public fleet with two accepted members is listed" do
    fleet = listed_fleet

    assert_includes Fleet.directory, fleet
    assert_predicate fleet, :listed_in_directory?
  end

  test "a fleet that never chose follows public_fleet" do
    fleet = listed_fleet

    assert_nil fleet.listed
    assert_includes Fleet.directory, fleet
  end

  test "a fleet that opted out is not listed" do
    fleet = listed_fleet(listed: false)

    assert_not_includes Fleet.directory, fleet
    assert_not fleet.listed_in_directory?
  end

  test "a private fleet is not listed, even when it opted in" do
    fleet = listed_fleet(public_fleet: false, listed: true)

    assert_not_includes Fleet.directory, fleet
    assert_not fleet.listed_in_directory?
  end

  test "an unverified fleet is not listed" do
    fleet = create(:fleet, rsi_sid: "TEST", created_by: create(:user).id, members: [create(:user)])

    assert_not_includes Fleet.directory, fleet
    assert_not fleet.listed_in_directory?
  end

  test "a fleet whose verified SID is not its current SID is not listed" do
    fleet = listed_fleet
    fleet.update_column(:rsi_verified_sid, "OTHER")

    assert_not_includes Fleet.directory, fleet
  end

  test "a revoked verification leaves the directory with listed untouched" do
    fleet = listed_fleet(listed: true)
    fleet.revoke_rsi_verification!

    assert_not_includes Fleet.directory, fleet
    assert fleet.reload.listed
  end

  test "a fleet below the member floor is not listed" do
    fleet = listed_fleet(members: 1)

    assert_not_includes Fleet.directory, fleet
    assert_not fleet.listed_in_directory?
  end

  test "only accepted, kept members count towards the floor" do
    fleet = listed_fleet(members: 1)
    create(:fleet_membership, fleet:, user: create(:user), fleet_role: fleet.fleet_roles.ranked.last, aasm_state: :invited)
    discarded = create(:fleet_membership, fleet:, user: create(:user), fleet_role: fleet.fleet_roles.ranked.last, aasm_state: :accepted)
    discarded.discard

    assert_not_includes Fleet.directory, fleet
    assert_equal 1, fleet.member_count
  end

  test "a discarded fleet is not listed" do
    fleet = listed_fleet
    fleet.discard

    assert_not_includes Fleet.directory, fleet
  end

  test "with_member_count answers the count from the row" do
    fleet = listed_fleet(members: 3)
    loaded = Fleet.directory.with_member_count.find(fleet.id)

    assert_no_queries { assert_equal 3, loaded.member_count }
  end

  test "an FID naming a page under /fleets/ is rejected in any case" do
    fleet = build(:fleet, fid: "Directory")

    assert_not fleet.valid?
    assert_includes fleet.errors.messages_for(:fid), I18n.t("activerecord.errors.models.fleet.route_name")
  end

  test "the secondary activity must differ from the primary" do
    fleet = build(:fleet, primary_activity: "piracy", secondary_activity: "piracy")

    assert_not fleet.valid?
    assert_includes fleet.errors.messages_for(:secondary_activity),
      I18n.t("activerecord.errors.models.fleet.same_as_primary")
  end

  test "RSI values outside RSI's lists are rejected" do
    fleet = build(:fleet, primary_activity: "racing", commitment: "weekends", language: "xx", alignment: "chaotic")

    assert_not fleet.valid?
    assert_equal %i[alignment commitment language primary_activity], fleet.errors.attribute_names.sort
  end
end

# frozen_string_literal: true

require "test_helper"

class UserRsiHandleVerificationTest < ActiveSupport::TestCase
  test "a new user carries a verification token" do
    assert_match(/\AFLEETYARDS-[A-Z0-9]{10}\z/, create(:user).rsi_verification_token)
  end

  test "a new handle clears the verification and the last check" do
    user = create(:user)
    user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    user.save!
    user.update_columns(rsi_verification_checked_at: Time.current)

    user.update!(rsi_handle: "OtherPilot")

    assert_not user.rsi_handle_verified?
    assert_nil user.rsi_handle_verified_via
    assert_nil user.rsi_handle_verified_at
    assert_nil user.rsi_verification_status
    assert_nil user.rsi_verification_checked_at
  end

  test "a Citizen iD verification takes the handle from the account that proved it through the bio" do
    holder = create(:user)
    holder.verify_rsi_handle("TestPilot", via: :rsi_profile)
    holder.save!

    user = create(:user)
    user.verify_rsi_handle("testpilot", via: :citizenid)

    assert_difference -> { Notification.where(user: holder, notification_type: :rsi_handle_verification_lost).count }, 1 do
      user.save!
    end

    assert user.reload.rsi_handle_verified_via_citizenid?
    assert_not holder.reload.rsi_handle_verified?
  end

  test "verifying again the handle an account already holds tells nobody" do
    user = create(:user)
    user.verify_rsi_handle("TestPilot", via: :citizenid)
    user.save!

    assert_no_difference -> { Notification.count } do
      user.verify_rsi_handle("TestPilot", via: :citizenid)
      user.save!
    end
  end

  test "two accounts can name the same handle while neither has proved it" do
    create(:user, rsi_handle: "TestPilot")

    assert create(:user, rsi_handle: "TestPilot").persisted?
  end

  test "Citizen iD links only a handle it verified" do
    user = create(:user)
    user.omniauth_connections.create!(provider: :citizenid, uid: "abc")
    user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    user.save!

    assert_nil user.citizenid_profile_url
  end

  def with_org_list(handle: "TestPilot", via: :rsi_profile, sids: %w[MAIN])
    create(:user).tap do |user|
      user.verify_rsi_handle(handle, via:)
      user.save!
      user.store_rsi_organizations(sids, read_at: Time.current)
    end
  end

  def membership_of(user, sid: "MAIN")
    create(:fleet, rsi_sid: sid, members: [user]).fleet_memberships.find_by(user:)
  end

  test "a stored org list verifies the memberships whose fleet it names" do
    user = with_org_list
    named = membership_of(user)
    other = membership_of(user, sid: "OTHER")

    user.store_rsi_organizations(%w[main], read_at: Time.current)

    assert named.reload.verified?
    assert_not other.reload.verified?
  end

  test "an older read does not replace a newer list" do
    user = with_org_list
    user.update_columns(rsi_handle_verified_at: 1.day.ago)
    membership = membership_of(user)

    assert_not user.store_rsi_organizations([], read_at: 1.hour.ago)

    assert_equal %w[MAIN], user.reload.rsi_organization_sids
    assert membership.reload.verified?
  end

  test "a read begun before a revoke and a new verification is dropped" do
    user = with_org_list
    read_at = Time.current

    user.revoke_rsi_handle_verification!
    user.reload.verify_rsi_handle("TestPilot", via: :rsi_profile)
    user.save!

    assert_not user.store_rsi_organizations(%w[OTHER], read_at:)
    assert_empty user.reload.rsi_organization_sids
  end

  test "a list read through a handle the user no longer has is dropped" do
    user = with_org_list

    assert_not user.store_rsi_organizations(%w[OTHER], read_at: Time.current, handle: "SomeoneElse")
  end

  test "revoking the handle empties the list and clears its memberships" do
    user = with_org_list
    membership = membership_of(user)

    user.revoke_rsi_handle_verification!

    assert_empty user.reload.rsi_organization_sids
    assert_not membership.reload.verified?
  end

  test "a handle taken by another account takes its list and memberships with it" do
    holder = with_org_list
    membership = membership_of(holder)

    user = create(:user)
    user.verify_rsi_handle("TestPilot", via: :citizenid)
    user.save!

    assert_empty holder.reload.rsi_organization_sids
    assert_not membership.reload.verified?
  end

  test "a new handle forgets what the old one's list said" do
    user = with_org_list
    membership = membership_of(user)

    user.update!(rsi_handle: "OtherPilot")

    assert_empty user.reload.rsi_organization_sids
    assert_not membership.reload.verified?
  end
end

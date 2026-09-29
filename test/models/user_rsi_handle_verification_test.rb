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
    user.update_columns(rsi_verification_checked_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

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
end

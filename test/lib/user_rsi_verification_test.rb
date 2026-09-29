# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class UserRsiVerificationTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, rsi_handle: "testpilot")
  end

  def stub_citizen_page(status: 200, handle: "TestPilot", bio: "", org_name: "Test Squadron", for_handle: "testpilot")
    body = format(Rails.root.join("test/fixtures/rsi/citizen_page.html").read, handle:, bio:, org_name:)

    stub_request(:get, "https://robertsspaceindustries.com/en/citizens/#{for_handle}").to_return(status:, body:)
  end

  def verify(user = @user)
    UserRsiVerification.new(user).run
  end

  test "the token in the bio verifies the handle in the page's spelling" do
    stub_citizen_page(bio: @user.rsi_verification_token)

    assert_equal :verified, verify

    @user.reload
    assert @user.rsi_handle_verified?
    assert @user.rsi_handle_verified_via_rsi_profile?
    assert @user.rsi_verification_verified?
    assert_equal "TestPilot", @user.rsi_handle
    assert @user.rsi_handle_verified_at.present?
  end

  test "a bio without the token leaves the handle unverified" do
    stub_citizen_page

    assert_equal :token_missing, verify
    assert_not @user.reload.rsi_handle_verified?
    assert @user.rsi_verification_token_missing?
  end

  test "the token in the main org's name does not count" do
    stub_citizen_page(org_name: @user.rsi_verification_token)

    assert_equal :token_missing, verify
    assert_not @user.reload.rsi_handle_verified?
  end

  test "a page for a different handle does not count" do
    stub_citizen_page(handle: "SomeoneElse", bio: @user.rsi_verification_token)

    assert_equal :handle_mismatch, verify
    assert_not @user.reload.rsi_handle_verified?
  end

  test "a citizen RSI does not know is reported as not found" do
    stub_citizen_page(status: 404)

    assert_equal :not_found, verify
  end

  test "a user without a handle cannot be checked" do
    @user.update!(rsi_handle: nil)

    assert_equal :failed, verify
  end

  test "the latest proof takes the handle from the account that held it" do
    holder = create(:user)
    holder.verify_rsi_handle("TestPilot", via: :citizenid)
    holder.save!
    stub_citizen_page(bio: @user.rsi_verification_token)

    assert_difference -> { Notification.where(user: holder, notification_type: :rsi_handle_verification_lost).count }, 1 do
      verify
    end

    assert @user.reload.rsi_handle_verified?
    assert_not holder.reload.rsi_handle_verified?
    assert_nil holder.rsi_handle_verified_via
    assert_equal "TestPilot", holder.rsi_handle
  end

  test "an answer about a handle the user has since changed is dropped" do
    @user.update_columns(rsi_verification_status: :pending, rsi_verification_checked_at: Time.current.floor(6)) # rubocop:disable Rails/SkipsModelValidations
    check = UserRsiVerification.new(@user.reload)
    stub_citizen_page(bio: @user.rsi_verification_token)

    User.find(@user.id).update!(rsi_handle: "otherpilot")

    assert_nil check.run
    @user.reload
    assert_not @user.rsi_handle_verified?
    assert_nil @user.rsi_verification_status
  end

  test "an answer from an older check is dropped" do
    @user.update_columns(rsi_verification_checked_at: 2.minutes.ago.floor(6)) # rubocop:disable Rails/SkipsModelValidations
    check = UserRsiVerification.new(@user.reload)
    @user.update_columns(rsi_verification_status: :pending, rsi_verification_checked_at: Time.current.floor(6)) # rubocop:disable Rails/SkipsModelValidations
    stub_citizen_page

    assert_nil check.run
    assert @user.reload.rsi_verification_pending?
  end

  test "an answer after the rotation of the token is dropped" do
    @user.update_columns(rsi_verification_status: :pending, rsi_verification_checked_at: Time.current.floor(6)) # rubocop:disable Rails/SkipsModelValidations
    check = UserRsiVerification.new(@user.reload)
    stub_citizen_page(bio: @user.rsi_verification_token)

    User.find(@user.id).generate_rsi_verification_token!

    assert_nil check.run
    assert_not @user.reload.rsi_handle_verified?
  end

  test "an answer from a check started before a revoke is dropped" do
    @user.update_columns(rsi_verification_status: :pending, rsi_verification_checked_at: Time.current.floor(6)) # rubocop:disable Rails/SkipsModelValidations
    check = UserRsiVerification.new(@user.reload)
    stub_citizen_page(bio: @user.rsi_verification_token)

    other = User.find(@user.id)
    other.verify_rsi_handle("testpilot", via: :citizenid)
    other.save!
    other.revoke_rsi_handle_verification!

    assert_nil check.run
    assert_not @user.reload.rsi_handle_verified?
  end
end

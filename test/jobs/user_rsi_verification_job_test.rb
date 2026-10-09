# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class UserRsiVerificationJobTest < ActiveSupport::TestCase
  test "a check that raises is recorded as failed rather than left pending" do
    user = create(:user, rsi_handle: "testpilot")
    user.update_columns(rsi_verification_status: :pending)
    stub_request(:get, "https://robertsspaceindustries.com/en/citizens/testpilot").to_raise(StandardError.new("boom"))

    UserRsiVerificationJob.new.perform(user.id)

    assert user.reload.rsi_verification_failed?
  end

  test "a deleted user is not checked" do
    assert_nil UserRsiVerificationJob.new.perform(SecureRandom.uuid)
  end
end

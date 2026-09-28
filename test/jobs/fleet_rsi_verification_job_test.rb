# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FleetRsiVerificationJobTest < ActiveSupport::TestCase
  test "a check that raises is recorded as failed rather than left pending" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST", rsi_verification_status: :pending)
    fleet.generate_rsi_verification_token!
    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_raise(StandardError.new("boom"))

    FleetRsiVerificationJob.new.perform(fleet.id)

    assert fleet.reload.rsi_verification_failed?
  end

  test "a discarded fleet is not checked" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    fleet.discard

    assert_nil FleetRsiVerificationJob.new.perform(fleet.id)
  end
end

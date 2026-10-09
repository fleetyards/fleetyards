# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FleetRsiVerificationJobTest < ActiveSupport::TestCase
  test "a check that raises is recorded as failed rather than left pending" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    fleet.generate_rsi_verification_token!
    fleet.update_columns(rsi_verification_status: :pending)
    stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST").to_raise(StandardError.new("boom"))

    FleetRsiVerificationJob.new.perform(fleet.id)

    assert fleet.reload.rsi_verification_failed?
  end

  test "a discarded fleet is not checked" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    fleet.discard

    assert_nil FleetRsiVerificationJob.new.perform(fleet.id)
  end

  test "a failure after the check answered keeps its answer" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    fleet.update_columns(rsi_verification_status: :verified)

    job = FleetRsiVerificationJob.new
    FleetRsiVerification.alias_method(:original_run, :run)
    FleetRsiVerification.define_method(:run) { raise "late failure" }
    begin
      job.perform(fleet.id)
    ensure
      FleetRsiVerification.alias_method(:run, :original_run)
      FleetRsiVerification.remove_method(:original_run)
    end

    assert fleet.reload.rsi_verification_verified?
  end
end

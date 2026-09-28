# frozen_string_literal: true

require "test_helper"

class FleetRsiSidTest < ActiveSupport::TestCase
  test "an org URL is stored as its SID" do
    fleet = create(:fleet, rsi_sid: "https://robertsspaceindustries.com/en/orgs/test")

    assert_equal "TEST", fleet.reload.rsi_sid
  end

  test "a citizen handle is rejected" do
    fleet = build(:fleet, rsi_sid: "@handle")

    assert_not fleet.valid?
    assert_includes fleet.errors.messages_for(:rsi_sid), I18n.t("activerecord.errors.models.fleet.not_an_rsi_sid")
  end

  test "a blank SID clears the column" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    fleet.update!(rsi_sid: "")

    assert_nil fleet.reload.rsi_sid
  end

  test "a row stored before the check does not block an unrelated edit" do
    fleet = create(:fleet, created_by: create(:user).id)
    fleet.update_column(:rsi_sid, "@handle") # rubocop:disable Rails/SkipsModelValidations

    assert fleet.reload.update(name: "Renamed Fleet")
  end

  def verified_fleet(sid: "TEST")
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: sid)
    fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: sid, rsi_verification_status: :verified) # rubocop:disable Rails/SkipsModelValidations
    fleet
  end

  test "changing the SID clears the verification" do
    fleet = verified_fleet

    fleet.update!(rsi_sid: "OTHER")

    assert_not fleet.reload.rsi_verified?
    assert_nil fleet.rsi_verified_sid
  end

  test "an unrelated edit keeps the verification" do
    fleet = verified_fleet

    fleet.update!(name: "Renamed Fleet")

    assert fleet.reload.rsi_verified?
  end

  test "an unverified SID is not public" do
    fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")

    assert_nil fleet.public_rsi_sid
  end

  test "discarding a fleet frees its SID" do
    fleet = verified_fleet
    fleet.discard

    assert_nil fleet.reload.rsi_verified_sid
    assert verified_fleet.rsi_verified?
  end

  test "the verification cools down after a check" do
    fleet = create(:fleet, created_by: create(:user).id)
    fleet.update!(rsi_verification_checked_at: Time.current)

    assert fleet.rsi_verification_cooling_down?

    travel Fleet::RSI_VERIFICATION_COOLDOWN + 1.second do
      assert_not fleet.rsi_verification_cooling_down?
    end
  end
end

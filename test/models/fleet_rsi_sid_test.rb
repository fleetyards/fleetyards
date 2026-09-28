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
end

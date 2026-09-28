# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260928120000_normalise_fleet_rsi_sids.rb")

class NormaliseFleetRsiSidsTest < ActiveSupport::TestCase
  # Raw SQL: normalisation is part of the attribute's type, so nothing written
  # through ActiveRecord can produce the rows this migration is here to fix.
  def fleet_with_sid(value)
    fleet = create(:fleet, created_by: create(:user).id)
    Fleet.connection.exec_update(
      "UPDATE fleets SET rsi_sid = $1 WHERE id = $2", "test", [value, fleet.id]
    )
    fleet
  end

  def normalise
    NormaliseFleetRsiSids.new.up
  end

  test "an org URL becomes its SID" do
    fleet = fleet_with_sid("https://robertsspaceindustries.com/orgs/LEIR")

    normalise

    assert_equal "LEIR", fleet.reload.rsi_sid
  end

  test "padding, brackets and case are folded away" do
    padded = fleet_with_sid(" 1ARM")
    bracketed = fleet_with_sid("[GIT]")
    lowercase = fleet_with_sid("test")

    normalise

    assert_equal "1ARM", padded.reload.rsi_sid
    assert_equal "GIT", bracketed.reload.rsi_sid
    assert_equal "TEST", lowercase.reload.rsi_sid
  end

  test "a value that names no org is cleared" do
    handle = fleet_with_sid("@handle")
    record = fleet_with_sid("#1437915")
    citizen = fleet_with_sid("https://robertsspaceindustries.com/citizens/handle")

    normalise

    assert_nil handle.reload.rsi_sid
    assert_nil record.reload.rsi_sid
    assert_nil citizen.reload.rsi_sid
  end

  test "a discarded fleet is normalised too" do
    fleet = fleet_with_sid("test")
    fleet.discard

    normalise

    assert_equal "TEST", fleet.reload.rsi_sid
  end
end

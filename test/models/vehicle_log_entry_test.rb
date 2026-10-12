# frozen_string_literal: true

require "test_helper"

class VehicleLogEntryTest < ActiveSupport::TestCase
  test "dates a new entry now when no date is given" do
    freeze_time do
      entry = create(:vehicle_log_entry, logged_at: nil)

      assert_equal Time.current, entry.logged_at
    end
  end

  test "requires a title" do
    entry = build(:vehicle_log_entry, title: "")

    assert_not entry.valid?
    assert entry.errors.added?(:title, :blank)
  end

  test "goes with its vehicle through the bulk delete" do
    entry = create(:vehicle_log_entry)

    Vehicle.delete_with_dependents([entry.vehicle_id])

    assert_not VehicleLogEntry.exists?(entry.id)
  end
end

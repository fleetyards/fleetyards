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

  test "counts the public entries on the vehicle" do
    vehicle = create(:vehicle)
    entry = create(:vehicle_log_entry, :public, vehicle:)
    create(:vehicle_log_entry, vehicle:)

    assert_equal 1, vehicle.reload.public_log_entries_count

    entry.update!(public: false)
    assert_equal 0, vehicle.reload.public_log_entries_count

    entry.update!(public: true)
    entry.destroy!
    assert_equal 0, vehicle.reload.public_log_entries_count
  end

  test "leaves the vehicle untouched by a private entry" do
    vehicle = create(:vehicle, updated_at: 1.day.ago)

    assert_no_changes -> { vehicle.reload.updated_at } do
      create(:vehicle_log_entry, vehicle:)
    end
  end

  test "goes with its vehicle through the bulk delete" do
    entry = create(:vehicle_log_entry)

    Vehicle.delete_with_dependents([entry.vehicle_id])

    assert_not VehicleLogEntry.exists?(entry.id)
  end

  test "the bulk delete drops a vehicle's picture without loading the vehicle" do
    vehicle = create(:vehicle)
    vehicle.update!(image: ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("ship.jpg").open, filename: "ship.jpg", content_type: "image/jpeg"
    ).signed_id)

    assert_difference -> { ActiveStorage::Attachment.where(record: vehicle, name: "image").count }, -1 do
      Vehicle.delete_with_dependents([vehicle.id])
    end
  end
end

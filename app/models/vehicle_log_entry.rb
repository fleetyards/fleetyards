# frozen_string_literal: true

class VehicleLogEntry < ApplicationRecord
  # No `touch`: no vehicle payload carries the log, and touching would run the
  # vehicle's broadcasts and fleet update for every entry written.
  belongs_to :vehicle

  scope :public_entries, -> { where(public: true) }
  scope :chronological, -> { order(logged_at: :desc, created_at: :desc) }

  before_validation -> { self.logged_at ||= Time.current }, on: :create

  after_commit :refresh_public_count, if: :public_count_affected?

  validates :title, presence: true, length: {maximum: 255}
  validates :logged_at, presence: true

  private def public_count_affected?
    destroyed? ? public? : saved_change_to_public?
  end

  # Written without callbacks for the reason `touch` is left off above; the
  # timestamp still moves so the cached public payloads pick the count up. The
  # row lock makes two writes to one log count one after the other, so the
  # earlier count can never land last.
  private def refresh_public_count
    Vehicle.transaction do
      # Locked as it is found, so a vehicle deleted meanwhile is simply gone
      # rather than an error on a write that already committed.
      vehicle = Vehicle.lock.find_by(id: vehicle_id)
      next if vehicle.blank?

      vehicle.update_columns(
        public_log_entries_count: vehicle.public_log_entries.count,
        updated_at: Time.current
      )
    end
  end
end

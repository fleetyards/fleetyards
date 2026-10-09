# frozen_string_literal: true

# What officers want every member to read when they open the fleet: a change of
# plan, a reminder, a welcome. Shown at the top of the dashboard until it
# expires or somebody takes it down.
class FleetAnnouncement < ApplicationRecord
  AVAILABLE_PRIVILEGES = [
    "fleet:announcements:manage"
  ].freeze

  # Posting is what officers do; reading needs nothing beyond membership.
  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:announcements:manage"],
    member: []
  }.freeze

  MANAGE_PRIVILEGES = ["fleet:manage", "fleet:announcements:manage"].freeze

  BODY_LIMIT = 2000

  belongs_to :fleet
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true, length: {maximum: BODY_LIMIT}
  validate :expires_in_the_future, if: -> { expires_at.present? && will_save_change_to_expires_at? }

  scope :active, -> { where(expires_at: nil).or(where(expires_at: Time.current..)) }

  # One that has already ended would be saved and never shown, and nobody could
  # reach it to take it down.
  private def expires_in_the_future
    errors.add(:expires_at, :invalid) if expires_at <= Time.current
  end
end

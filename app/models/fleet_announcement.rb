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

  # A board, not a log: past this the oldest are not news, and every one that
  # stands has to fit on the dashboard where it can be read and taken down.
  ACTIVE_LIMIT = 10

  belongs_to :fleet
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true, length: {maximum: BODY_LIMIT}
  validate :expires_in_the_future, if: -> { expires_at.present? }
  validate :within_active_limit, on: :create

  scope :active, -> { where(expires_at: nil).or(where(expires_at: Time.current..)) }

  # One that has already ended would be saved and never shown, and nobody could
  # reach it to take it down -- whether the end was just set or was kept while
  # the announcement was being edited and ran out meanwhile.
  private def expires_in_the_future
    errors.add(:expires_at, :already_passed) if expires_at <= Time.current
  end

  private def within_active_limit
    return if fleet.blank?
    return if fleet.fleet_announcements.active.count < ACTIVE_LIMIT

    errors.add(:base, :announcement_limit_reached, count: ACTIVE_LIMIT)
  end
end

# frozen_string_literal: true

class GameEvent < ApplicationRecord
  paginates_per 24

  DEFAULT_SORTING_PARAMS = "starts_at desc"
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "startsAt asc", "startsAt desc",
    "createdAt asc", "createdAt desc"
  ]

  # The same eight as fleet events, so a game event takes the same mission art
  # and category colour wherever the two are shown side by side.
  enum :category, {
    other: 0,
    ship_combat: 1,
    ground_combat: 2,
    combined_combat: 3,
    mining: 4,
    salvage: 5,
    cargo_hauling: 6,
    exploration: 7
  }

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :url, format: {with: %r{\Ahttps?://\S+\z}}, allow_blank: true
  validate :ends_at_after_starts_at

  scope :published, -> { where(published: true) }

  # Running or still to come. An event without an end is still running: RSI
  # opens events like Discovery Month without saying when they close, so the
  # end is set once it is announced.
  scope :current, ->(now = Time.current) {
    where("game_events.ends_at IS NULL OR game_events.ends_at >= ?", now)
  }

  scope :overlapping, ->(from, to) {
    where("game_events.starts_at <= ?", to)
      .where("game_events.ends_at IS NULL OR game_events.ends_at >= ?", from)
  }

  def self.ransackable_attributes(auth_object = nil)
    ["title", "category", "published", "starts_at", "ends_at", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, :invalid)
  end
end

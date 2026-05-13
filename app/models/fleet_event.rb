# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_events
#
#  id                        :uuid             not null, primary key
#  archived_at               :datetime
#  auto_lock_enabled         :boolean          default(TRUE), not null
#  auto_lock_minutes_before  :integer          default(60), not null
#  briefing                  :text
#  cancelled_reason          :text
#  category                  :integer          default("other"), not null
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  ends_at                   :datetime
#  excluded_dates            :date             default([]), not null, is an Array
#  external_uid              :uuid             not null
#  location                  :string
#  max_attendees             :integer
#  meetup_location           :string
#  recurrence_count          :integer
#  recurrence_interval       :string
#  recurrence_until          :date
#  recurring                 :boolean          default(FALSE), not null
#  scenario                  :string
#  signup_approval           :string           default("direct"), not null
#  slug                      :string           not null
#  starting_soon_notified_at :datetime
#  starts_at                 :datetime         not null
#  status                    :string           default("draft"), not null
#  timezone                  :string           default("UTC"), not null
#  title                     :string           not null
#  visibility                :string           default("members"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  created_by_id             :uuid             not null
#  discord_event_id          :string
#  discord_message_id        :string
#  fleet_id                  :uuid             not null
#  mission_id                :uuid
#
# Indexes
#
#  index_fleet_events_on_external_uid            (external_uid) UNIQUE
#  index_fleet_events_on_fleet_id_and_recurring  (fleet_id,recurring)
#  index_fleet_events_on_fleet_id_and_slug       (fleet_id,slug) UNIQUE
#  index_fleet_events_on_fleet_id_and_starts_at  (fleet_id,starts_at)
#  index_fleet_events_on_fleet_id_and_status     (fleet_id,status)
#  index_fleet_events_on_mission_id              (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (mission_id => missions.id)
#
class FleetEvent < ApplicationRecord
  include AASM
  include ActiveStorageVariants

  paginates_per 30

  belongs_to :fleet, touch: true
  belongs_to :mission, optional: true
  belongs_to :created_by, class_name: "User"

  has_many :fleet_event_teams, dependent: :destroy
  has_many :fleet_event_ships, through: :fleet_event_teams
  has_many :fleet_event_signups, dependent: :destroy
  has_many :fleet_event_admins, dependent: :destroy
  has_many :event_admin_users, through: :fleet_event_admins, source: :user
  has_many :fleet_event_occurrence_states, dependent: :destroy

  has_one_attached :cover_image

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

  VISIBILITIES = %w[members officers fleet].freeze
  SIGNUP_APPROVALS = %w[direct confirmation_required].freeze
  RECURRENCE_INTERVALS = %w[daily weekly biweekly monthly].freeze

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :timezone, presence: true
  validates :visibility, inclusion: {in: VISIBILITIES}
  validates :signup_approval, inclusion: {in: SIGNUP_APPROVALS}
  validates :recurrence_interval,
    inclusion: {in: RECURRENCE_INTERVALS},
    if: :recurring?
  validates :recurrence_interval, absence: true, unless: :recurring?
  validate :recurrence_count_or_until

  before_validation :set_external_uid, on: :create
  before_validation :ensure_id, on: :create
  before_validation :default_cover_image_preset
  before_save :update_slug

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :past, -> { where("starts_at < ?", Time.current).order(starts_at: :desc) }
  scope :active_status, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  AVAILABLE_PRIVILEGES = [
    "fleet:events:read",
    "fleet:events:create",
    "fleet:events:update",
    "fleet:events:delete",
    "fleet:events:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:events:manage"],
    member: ["fleet:events:read"]
  }.freeze

  aasm column: :status, timestamps: true, whiny_transitions: false do
    state :draft, initial: true
    state :open
    state :locked
    state :active
    state :completed
    state :cancelled

    event :publish do
      transitions from: :draft, to: :open
    end

    event :lock_signups do
      transitions from: :open, to: :locked
    end

    event :unlock_signups do
      transitions from: :locked, to: :open
    end

    event :start do
      transitions from: [:open, :locked], to: :active
    end

    event :complete do
      transitions from: :active, to: :completed
    end

    event :cancel do
      transitions from: [:draft, :open, :locked, :active], to: :cancelled
    end
  end

  def archived?
    archived_at.present?
  end

  def event_admin_role_for(user)
    return nil unless user
    fleet_event_admins.find_by(user_id: user.id)&.role
  end

  def event_admin?(user)
    event_admin_role_for(user) == "admin" || created_by_id == user&.id
  end

  def event_moderator_or_admin?(user)
    %w[admin moderator].include?(event_admin_role_for(user)) ||
      created_by_id == user&.id
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  # Returns all slots across event teams and ships (polymorphic).
  def slots
    team_ids = fleet_event_teams.pluck(:id)
    ship_ids = fleet_event_ships.pluck(:id)

    FleetEventSlot.where(slottable_type: "FleetEventTeam", slottable_id: team_ids)
      .or(FleetEventSlot.where(slottable_type: "FleetEventShip", slottable_id: ship_ids))
  end

  def signups_count
    fleet_event_signups.where.not(status: "withdrawn").count
  end

  def past?
    reference = ends_at.presence || starts_at
    reference.present? && reference < Time.current
  end

  def signups_open?
    status == "open" && !past?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug fleet_id mission_id status starts_at ends_at category scenario archived_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet mission created_by fleet_event_teams]
  end

  # Spawns a new event from a mission template, snapshotting the team/ship/slot tree.
  def self.from_mission!(mission, attrs = {})
    transaction do
      event = mission.fleet.fleet_events.create!(
        attrs.reverse_merge(
          mission_id: mission.id,
          title: default_title(mission, attrs[:starts_at]),
          description: mission.description,
          briefing: nil,
          category: mission.category,
          scenario: mission.scenario,
          cover_image_preset: mission.cover_image_preset
        )
      )

      mission.mission_teams.includes(mission_ships: :model, mission_slots: :model_position).order(:position).each do |team|
        event_team = event.fleet_event_teams.create!(
          source_team_id: team.id,
          title: team.title,
          description: team.description,
          position: team.position
        )

        team.mission_slots.order(:position).each do |slot|
          FleetEventSlot.create!(
            slottable: event_team,
            source_slot_id: slot.id,
            model_position_id: slot.model_position_id,
            title: slot.title,
            description: slot.description,
            position: slot.position
          )
        end

        team.mission_ships.order(:position).each do |ship|
          event_ship = event_team.fleet_event_ships.create!(
            source_ship_id: ship.id,
            model_id: ship.model_id,
            title: ship.title,
            description: ship.description,
            classification: ship.classification,
            focus: ship.focus,
            min_size: ship.min_size,
            max_size: ship.max_size,
            min_crew: ship.min_crew,
            min_cargo: ship.min_cargo,
            position: ship.position
          )

          ship.mission_slots.order(:position).each do |slot|
            FleetEventSlot.create!(
              slottable: event_ship,
              source_slot_id: slot.id,
              model_position_id: slot.model_position_id,
              title: slot.title,
              description: slot.description,
              position: slot.position
            )
          end
        end
      end

      event
    end
  end

  def self.default_title(mission, starts_at)
    date_str = (starts_at.is_a?(Time) || starts_at.is_a?(DateTime)) ? starts_at.strftime("%b %-d, %Y") : "TBD"
    "#{mission.title} — #{date_str}"
  end

  # Returns occurrence start times falling within [from, to]. For
  # one-off events this is `[starts_at]` if it lies in the range.
  # Recurring events are expanded forward from `starts_at` honouring
  # `recurrence_until`, `recurrence_count`, and `excluded_dates`.
  def occurrences(from:, to:)
    from = from.to_time
    to = to.to_time
    return [] if starts_at.blank?

    unless recurring?
      return starts_at.between?(from, to) ? [starts_at] : []
    end

    interval_step = recurrence_step
    return [] if interval_step.nil?

    result = []
    cursor = starts_at
    limit = recurrence_count.presence
    iterations = 0
    until_time = recurrence_until&.end_of_day&.in_time_zone(timezone || "UTC")

    while cursor <= to && (limit.nil? || iterations < limit)
      break if until_time && cursor > until_time

      excluded = excluded_dates.any? do |d|
        date = d.is_a?(String) ? Date.parse(d) : d
        date == cursor.to_date
      end

      result << cursor if cursor >= from && !excluded
      cursor = advance_cursor(cursor, interval_step)
      iterations += 1
    end

    result
  end

  # Returns the soonest occurrence at or after `after`, or nil if the
  # series has ended.
  def next_occurrence(after: Time.current)
    occurrences(from: after, to: 1.year.from_now).first
  end

  def skip_occurrence!(date)
    return if date.blank?
    parsed = date.is_a?(Date) ? date : Date.parse(date.to_s)
    return if excluded_dates.include?(parsed)

    update!(excluded_dates: excluded_dates + [parsed])
  end

  def end_series_at!(date)
    return if date.blank?
    parsed = date.is_a?(Date) ? date : Date.parse(date.to_s)
    update!(recurrence_until: parsed - 1.day)
  end

  # Find or build the per-occurrence state row for a given date. nil-safe.
  def occurrence_state_for(date, build: false)
    return nil if date.blank?
    parsed = date.is_a?(Date) ? date : Date.parse(date.to_s)
    state = fleet_event_occurrence_states.find_by(occurrence_date: parsed)
    return state if state
    build ? fleet_event_occurrence_states.build(occurrence_date: parsed) : nil
  end

  private def recurrence_step
    case recurrence_interval
    when "daily" then {value: 1, unit: :days}
    when "weekly" then {value: 1, unit: :weeks}
    when "biweekly" then {value: 2, unit: :weeks}
    when "monthly" then {value: 1, unit: :months}
    end
  end

  private def advance_cursor(cursor, step)
    cursor + step[:value].public_send(step[:unit])
  end

  private def recurrence_count_or_until
    return unless recurrence_count.present? && recurrence_until.present?
    errors.add(:base, :recurrence_count_xor_until)
  end

  private def set_external_uid
    self.external_uid ||= SecureRandom.uuid
  end

  private def ensure_id
    self.id ||= SecureRandom.uuid
  end

  # Slugs are prefixed with the first segment of the event id. The prefix
  # alone guarantees uniqueness within a fleet, so any title-based collisions
  # disappear and URLs read as `<short-id>-<title>` (similar to GitHub issues).
  private def update_slug
    base = generate_slug(title)
    prefix = id.to_s.split("-").first
    candidate = prefix.present? ? "#{prefix}-#{base}" : base
    return if slug == candidate

    self.slug = candidate
  end

  # When the form doesn't pick a preset, default to the category's base
  # asset. Mirrors the frontend useMissionCover fallback so the same cover
  # appears in the UI, the OG image, and the Discord push.
  private def default_cover_image_preset
    return if cover_image_preset.present?
    return if category.blank?

    self.cover_image_preset = category.to_s
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_events
#
#  id                        :uuid             not null, primary key
#  active_at                 :datetime
#  archived_at               :datetime
#  auto_lock_enabled         :boolean          default(TRUE), not null
#  auto_lock_minutes_before  :integer          default(60), not null
#  briefing                  :text
#  cancelled_at              :datetime
#  cancelled_reason          :text
#  category                  :integer          default("other"), not null
#  completed_at              :datetime
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  ends_at                   :datetime
#  excluded_dates            :date             default([]), not null, is an Array
#  external_uid              :uuid             not null
#  location                  :string
#  locked_at                 :datetime
#  max_attendees             :integer
#  meetup_location           :string
#  open_at                   :datetime
#  published_at              :datetime
#  recurrence_count          :integer
#  recurrence_every          :integer          default(1), not null
#  recurrence_interval       :string
#  recurrence_until          :date
#  recurrence_weekdays       :integer          default([]), not null, is an Array
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

  has_one :payout_ledger, as: :subject, dependent: :destroy

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

  include SquadronRestrictable

  # "squadron" narrows it to the squadrons named in `fleet_squadrons`; see
  # SquadronRestrictable.
  VISIBILITIES = %w[members officers fleet squadron].freeze
  SIGNUP_APPROVALS = %w[direct confirmation_required].freeze
  # "biweekly" predates `recurrence_every` and is still accepted from API
  # clients; it is stored as weekly every 2.
  RECURRENCE_INTERVALS = %w[daily weekly biweekly monthly].freeze
  RECURRENCE_FREQUENCIES = %w[daily weekly monthly].freeze
  MAX_RECURRENCE_EVERY = 99
  UPCOMING_OCCURRENCES_LIMIT = 12

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :timezone, presence: true
  validates :visibility, inclusion: {in: VISIBILITIES}
  validates :signup_approval, inclusion: {in: SIGNUP_APPROVALS}
  validates :recurrence_interval,
    inclusion: {in: RECURRENCE_INTERVALS},
    if: :recurring?
  validates :recurrence_interval, absence: true, unless: :recurring?
  validates :recurrence_every,
    numericality: {only_integer: true, in: 1..MAX_RECURRENCE_EVERY}
  validate :recurrence_count_or_until
  validate :recurrence_weekdays_are_weekdays

  before_validation :set_external_uid, on: :create
  before_validation :ensure_id, on: :create
  before_validation :default_cover_image_preset
  before_validation :normalize_recurrence
  before_save :update_slug
  before_save :stamp_published_at, if: :will_save_change_to_status?

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :past, -> { where("starts_at < ?", Time.current).order(starts_at: :desc) }
  scope :active_status, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  # A recurring event keeps its whole series on the parent row, so filtering by
  # starts_at would drop a weekly op that began before the cutoff along with
  # every occurrence it still has ahead of it. Recurring rows are therefore only
  # excluded when the series can be shown to have finished; a count-bounded or
  # open-ended series stays, and its RRULE simply yields nothing in the past.
  scope :starting_after, ->(cutoff) {
    where(
      "(recurring IS NOT TRUE AND starts_at >= :cutoff) OR " \
      "(recurring IS TRUE AND (recurrence_until IS NULL OR recurrence_until >= :cutoff_date))",
      cutoff: cutoff, cutoff_date: cutoff.to_date
    )
  }

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

  # Every one of these is already ransackable and already emits an ORDER BY --
  # what was missing is the list saying which a client may ask for, so the
  # controller had nothing to filter an arbitrary attribute against.
  DEFAULT_SORTING_PARAMS = "starts_at asc"
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "startsAt asc", "startsAt desc",
    "status asc", "status desc",
    "category asc", "category desc",
    "createdAt asc", "createdAt desc"
  ].freeze

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

      mission.mission_teams.includes(mission_ships: [:model, :mission_ship_models], mission_slots: :model_position).order(:position).each do |team|
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
          event_ship = event_team.fleet_event_ships.new(
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

          # Before the save, and not only so the event arrives with the list: a
          # spot whose whole spec is a list has nothing in its columns, so saving
          # first left model_or_filter_required with nothing to accept.
          ship.mission_ship_models.order(:position).each_with_index do |allowed, index|
            event_ship.fleet_event_ship_models.build(
              model_id: allowed.model_id,
              position: index
            )
          end

          event_ship.save!

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
  # `recurrence_until`, `recurrence_count`, and `excluded_dates`; an
  # excluded date still counts towards `recurrence_count`, as EXDATE does
  # against COUNT in the calendar feed.
  def occurrences(from:, to:, include_excluded: false)
    from = from.to_time
    to = to.to_time
    return [] if starts_at.blank?

    unless recurring?
      return starts_at.between?(from, to) ? [starts_at] : []
    end

    return [] unless RECURRENCE_FREQUENCIES.include?(recurrence_frequency)

    limit = recurrence_count.presence
    # Date#end_of_day resolves in Time.zone, so the cutoff used to follow the
    # server's zone rather than the event's. in_time_zone on the date puts
    # midnight in the event's zone first, so this is the inclusive local
    # end-of-day an organiser means by "repeats until".
    until_time = recurrence_until&.in_time_zone(recurrence_time_zone)&.end_of_day
    excluded = excluded_dates.map { |d| d.is_a?(String) ? Date.parse(d) : d }.to_set

    result = []
    emitted = 0
    each_recurrence_start do |local|
      break if local > to
      break if limit && emitted >= limit
      break if until_time && local > until_time

      emitted += 1
      # Occurrence dates are keyed in Time.zone everywhere they are stored
      # (signups, occurrence states, excluded dates), so the result is handed
      # back in that zone rather than the event's.
      cursor = local.in_time_zone(Time.zone)
      next if cursor < from
      next if !include_excluded && excluded.include?(cursor.to_date)

      result << cursor
    end

    result
  end

  # "biweekly" rows written before `recurrence_every` existed read as weekly
  # every 2 until their next save normalises them.
  def recurrence_frequency
    (recurrence_interval == "biweekly") ? "weekly" : recurrence_interval
  end

  def recurrence_step
    (recurrence_interval == "biweekly") ? 2 : recurrence_every.to_i.clamp(1, MAX_RECURRENCE_EVERY)
  end

  # The weekdays a weekly series falls on, in the event's zone (0 = Sunday).
  # Empty means the weekday of `starts_at` alone.
  def recurrence_days
    return [] unless recurrence_frequency == "weekly"

    days = Array(recurrence_weekdays).map(&:to_i)
    return [] if days.empty?

    (days + [recurrence_start_wday]).compact.uniq.sort
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

  private def recurrence_time_zone
    timezone.presence || "UTC"
  end

  private def recurrence_start_wday
    starts_at&.in_time_zone(recurrence_time_zone)&.wday
  end

  # Yields every candidate start in the event's zone, in order, without end.
  # Stepping from `starts_at` rather than from the previous occurrence keeps a
  # monthly series on the 31st from settling on the 28th after February, and
  # doing it in the event's zone keeps the wall-clock time across DST.
  private def each_recurrence_start
    local_start = starts_at.in_time_zone(recurrence_time_zone)
    step = recurrence_step
    days = recurrence_days

    if days.any?
      # Weeks start on Monday (WKST=MO in the feed), so "every 2 weeks on
      # Tue + Thu" pairs the same days in Fleetyards and calendar clients.
      week_start = local_start.to_date.beginning_of_week(:monday)
      offsets = days.map { |wday| (wday - 1) % 7 }.sort

      (0..).each do |week|
        base = week_start + (week * step).weeks
        offsets.each do |offset|
          date = base + offset
          candidate = local_start.change(year: date.year, month: date.month, day: date.day)
          yield candidate unless candidate < local_start
        end
      end
    else
      unit = {"daily" => :days, "weekly" => :weeks, "monthly" => :months}.fetch(recurrence_frequency)
      (0..).each { |index| yield local_start + (index * step).public_send(unit) }
    end
  end

  private def normalize_recurrence
    unless recurring?
      self.recurrence_every = 1
      self.recurrence_weekdays = []
      return
    end

    if recurrence_interval == "biweekly"
      self.recurrence_interval = "weekly"
      self.recurrence_every = 2
    end

    days = recurrence_days
    self.recurrence_weekdays = (days == [recurrence_start_wday]) ? [] : days
  end

  private def recurrence_weekdays_are_weekdays
    return if Array(recurrence_weekdays).all? { |day| day.is_a?(Integer) && day.between?(0, 6) }

    errors.add(:recurrence_weekdays, :inclusion)
  end

  private def recurrence_count_or_until
    return unless recurrence_count.present? && recurrence_until.present?
    errors.add(:base, :recurrence_count_xor_until)
  end

  # `open_at` is written by aasm on every transition into `open`, so unlocking
  # signups moves it. This one is set on the first publish and never again,
  # which is what a lead time has to measure against.
  private def stamp_published_at
    return unless status == "open"

    self.published_at ||= Time.current
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

  def officers_only?
    visibility == "officers"
  end

  # Whether everybody on the fleet's Discord server may read about it. A
  # scheduled event and the fleet's channel both reach the whole server, so an
  # event kept to squadrons or to officers goes to their own channels instead.
  def discord_guild_wide?
    !squadron_restricted? && !officers_only?
  end
end

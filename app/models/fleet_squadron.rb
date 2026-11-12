# frozen_string_literal: true

require "lexorank/rankable"

class FleetSquadron < ApplicationRecord
  include ActiveStorageVariants

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 24
  paginates_all

  belongs_to :fleet, touch: true

  # The fleet's own order, a lexorank like FleetRole's: a move writes one row,
  # and the unique index means two squadrons can never share a place.
  rank!(group_by: :fleet)

  has_many :fleet_squadron_memberships, dependent: :destroy
  has_many :fleet_squadron_assignments, dependent: :destroy
  has_many :fleet_squadron_requests, dependent: :destroy
  has_many :fleet_event_teams, dependent: nil
  has_many :mission_teams, dependent: nil
  has_many :fleet_squadron_flights, dependent: :destroy
  has_many :fleet_memberships, through: :fleet_squadron_memberships
  has_many :users, through: :fleet_memberships

  has_one_attached :icon

  validates :icon, no_vector_image: true

  # Cropped to its opaque bounds before any representation exists. An emblem
  # exported from a design tool usually sits inside a transparent canvas, and
  # every size built from it carries that padding -- so at 20px on an avatar the
  # mark itself would be a handful of pixels.
  trim_attachment :icon

  AVAILABLE_PRIVILEGES = [
    "fleet:squadrons:read",
    "fleet:squadrons:create",
    "fleet:squadrons:update",
    "fleet:squadrons:delete",
    "fleet:squadrons:members:manage",
    "fleet:squadrons:manage"
  ].freeze

  # Officers organise the people, admins decide which squadrons exist. Admin is
  # empty because `fleet:manage` already stands for the whole set and every
  # squadron policy admits on it, the way the other fleet resources seed.
  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:squadrons:read", "fleet:squadrons:members:manage"],
    member: ["fleet:squadrons:read"]
  }.freeze

  # The superset, spelled once. Every squadron rule admits on it in addition to
  # the specific privilege it asks for.
  MANAGE_PRIVILEGES = ["fleet:manage", "fleet:squadrons:manage"].freeze

  READ_PRIVILEGES = [*MANAGE_PRIVILEGES, "fleet:squadrons:read"].freeze

  MEMBERS_MANAGE_PRIVILEGES = [*MANAGE_PRIVILEGES, "fleet:squadrons:members:manage"].freeze

  COLOR_FORMAT = /\A#(?:\h{3}|\h{6})\z/

  validates :name,
    presence: true,
    length: {maximum: 255},
    uniqueness: {case_sensitive: false, scope: :fleet_id}

  # "Alpha Wing" and "alpha-wing" are two names the uniqueness check above lets
  # through, and both parameterize to one slug -- which the unique index would
  # reject as a 500. Validating the derived value turns that into the 400 a
  # duplicate name already gets.
  validates :slug, uniqueness: {scope: :fleet_id}

  validates :color, format: {with: COLOR_FORMAT}, allow_blank: true

  validates :discord_channel_id, format: {with: ::Discord::ApiClient::SNOWFLAKE_FORMAT}, allow_nil: true

  # The card carries this on a line or two, so it is held to a line or two.
  validates :short_description, length: {maximum: 255}, allow_blank: true

  validates :description, length: {maximum: 5000}, allow_blank: true

  # A squadron is where somebody belongs, so belonging to two at once is the
  # exception: a member holds at most one ordinary squadron in a fleet. A team
  # is the exception made explicit -- a standing detachment, a trade wing, a
  # crew that cuts across the roster -- and sits outside the rule entirely, on
  # either side of it.
  validate :exclusivity_is_not_already_broken, if: -> { exclusive? && team_changed? }

  before_validation :normalize_color
  before_validation :normalize_discord_channel_id
  before_validation :update_slugs

  # Appended rather than inserted: a squadron somebody has just made belongs at
  # the end of the order somebody else arranged, not in the middle of it.
  before_create :set_rank

  # Collected before the assignments go and answered after, because the
  # question -- "is this record still restricted to anybody?" -- can only be
  # asked once this squadron has stopped being one of the answers.
  before_destroy :remember_restricted_records, prepend: true

  # The foreign key clears the teams built from this squadron inside the
  # database, where no touch reaches the event or template they belong to.
  before_destroy :touch_team_parents

  # A squadron flies together, so it starts with flights; a team is a side
  # group members join on top of their squadron and starts without them.
  # Whatever the creator chose stands.
  before_validation :default_flights_enabled, on: :create

  def flights_enabled=(value)
    @flights_enabled_chosen = true
    super
  end

  # Switching flights back on picks up the invitations it held back. Flagged by
  # the save that switches them, because a touch later commits with that save's
  # changes still on record.
  before_update -> { @enabling_flights = will_save_change_to_flights_enabled?(to: true) }
  after_update_commit :offer_held_slots, if: -> { @enabling_flights }
  after_rollback -> { @enabling_flights = false }
  after_destroy :release_restricted_records

  # The fleet's own order, which is the point of having one. Sorting by name is
  # still offered; it is simply not what the list opens on.
  DEFAULT_SORTING_PARAMS = "rank asc"
  ALLOWED_SORTING_PARAMS = ["name asc", "name desc", "createdAt asc", "createdAt desc"]

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug fleet_id rank team created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  scope :teams, -> { where(team: true) }
  scope :exclusive, -> { where(team: false) }

  # Everything that is not a team. Named for what the rule is about rather than
  # for the column, because the column marks the exception and every read of it
  # is about the ordinary case.
  def exclusive?
    !team?
  end

  # The members this squadron already holds who are in another exclusive one.
  # Named rather than counted, because "three members are in two squadrons at
  # once" is not something anybody can act on.
  def exclusive_conflicts
    return FleetMembership.none unless fleet

    FleetMembership
      .where(id: accepted_fleet_memberships.select(:id))
      .where(
        id: FleetSquadronMembership
          .joins(:fleet_squadron)
          .where(fleet_squadrons: {fleet_id: fleet_id, team: false})
          .where.not(fleet_squadron_id: id)
          .select(:fleet_membership_id)
      )
  end

  # Turning a team back into an ordinary squadron cannot be allowed to leave the
  # rule already broken -- nothing would ever repair it, and every later save of
  # an untouched squadron would then fail on a state somebody else created.
  private def exclusivity_is_not_already_broken
    conflicting = exclusive_conflicts.includes(:user).limit(5)

    return if conflicting.empty?

    errors.add(:team, :conflicting_members, members: conflicting.map { |m| m.user&.username }.compact.to_sentence)
  end

  private def remember_restricted_records
    @restricted_records = fleet_squadron_assignments.map(&:assignable).compact
  end

  private def touch_team_parents
    FleetEvent.where(id: fleet_event_teams.select(:fleet_event_id)).touch_all
    Mission.where(id: mission_teams.select(:mission_id)).touch_all
  end

  private def default_flights_enabled
    self.flights_enabled = !team? unless @flights_enabled_chosen
  end

  private def offer_held_slots
    @enabling_flights = false
    FleetEventSlot
      .where(id: FleetEventSlotCandidate.waiting
        .where(fleet_squadron_membership_id: fleet_squadron_memberships.select(:id))
        .select(:fleet_event_slot_id))
      .find_each { |slot| FleetEvents::SlotInvites.new(slot).offer! }
  end

  private def release_restricted_records
    @restricted_records.to_a.each(&:release_squadron_restriction!)
  end

  private def set_rank
    return if rank.present?

    move_to_end
  end

  # The accepted roster only. A squadron row can outlive the membership's
  # acceptance -- an invite withdrawn leaves the join behind until the
  # membership itself goes -- so every count and every vehicle list asks this
  # rather than the raw association.
  def accepted_fleet_memberships
    fleet_memberships.kept.accepted
  end

  # An eager-loaded association answers without a query, which is what keeps a
  # list of squadrons from issuing one apiece. `count` on the relation would
  # ignore the loaded records and go to the database anyway.
  def member_count
    if fleet_memberships.loaded?
      fleet_memberships.count { |membership| membership.kept? && membership.accepted? }
    else
      accepted_fleet_memberships.count
    end
  end

  # The ships the named squadrons get from their members, as a subquery of
  # vehicle ids for a caller that already starts from the fleet's own ships --
  # which is what keeps every choice here a narrowing of what the fleet sees.
  #
  # A loaner follows its parent: picking a ship, or grouping it, brings the
  # loaners that come with it.
  def self.vehicle_ids_for(fleet_id:, squadron_ids:)
    filters = FleetSquadronMembership.ships_filters

    Vehicle
      .joins(<<~SQL.squish)
        INNER JOIN fleet_memberships squadron_owners
          ON squadron_owners.user_id = vehicles.user_id
          AND squadron_owners.fleet_id = #{connection.quote(fleet_id)}
          AND squadron_owners.discarded_at IS NULL
          AND squadron_owners.aasm_state = 'accepted'
        INNER JOIN fleet_squadron_memberships squadron_rows
          ON squadron_rows.fleet_membership_id = squadron_owners.id
      SQL
      .where("squadron_rows.fleet_squadron_id": squadron_ids)
      .where(<<~SQL.squish, all: filters["all"], hangar_group: filters["hangar_group"])
        squadron_rows.ships_filter = :all
        OR (
          squadron_rows.ships_filter = :hangar_group
          AND EXISTS (
            SELECT 1 FROM task_forces
            WHERE task_forces.hangar_group_id = squadron_rows.hangar_group_id
              AND (task_forces.vehicle_id = vehicles.id OR task_forces.vehicle_id = vehicles.vehicle_id)
          )
        )
        OR EXISTS (
          SELECT 1 FROM fleet_squadron_membership_vehicles picked
          WHERE picked.fleet_squadron_membership_id = squadron_rows.id
            AND (picked.vehicle_id = vehicles.id OR picked.vehicle_id = vehicles.vehicle_id)
        )
      SQL
      .select(:id)
  end

  # The accepted members' users. Empty for an empty squadron, which is what
  # keeps a `where(user_id: [])` from widening to the whole fleet.
  def member_user_ids
    accepted_fleet_memberships.pluck(:user_id).compact
  end

  private def normalize_color
    self.color = color.presence&.strip&.downcase
  end

  private def normalize_discord_channel_id
    self.discord_channel_id = discord_channel_id.presence&.strip
  end
end

# frozen_string_literal: true

class FleetEvent < ApplicationRecord
  include AASM
  include ActiveStorageVariants

  paginates_per 30

  belongs_to :fleet, touch: true
  belongs_to :mission, optional: true
  belongs_to :created_by, class_name: "User"

  has_many :fleet_event_teams, dependent: :destroy
  has_many :fleet_event_ships, through: :fleet_event_teams

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

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :timezone, presence: true
  validates :visibility, inclusion: {in: VISIBILITIES}

  before_validation :set_external_uid, on: :create
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
    FleetEventSignup
      .where(fleet_event_slot_id: slots.pluck(:id))
      .where.not(status: "withdrawn")
      .count
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

  private def set_external_uid
    self.external_uid ||= SecureRandom.uuid
  end

  private def update_slug
    base = generate_slug(title)
    return if slug == base

    candidate = base
    suffix = 2
    while fleet.fleet_events.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end
end

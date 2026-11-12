# frozen_string_literal: true

class MissionShip < ApplicationRecord
  belongs_to :mission_team, touch: true
  belongs_to :model, optional: true
  # A flight's ship is a member's own rather than a kind of ship: the flight is
  # the same people in the same ships every time.
  belongs_to :vehicle, optional: true
  has_many :mission_slots, as: :slottable, dependent: :destroy
  has_many :mission_ship_models, dependent: :destroy
  has_many :allowed_models, through: :mission_ship_models, source: :model

  delegate :mission, to: :mission_team

  PILOT_TITLE = "Pilot"

  # A flight's ship always has someone to fly it. Committed rather than created,
  # so the seats taken from the model's positions are there to be asked first.
  after_commit :ensure_pilot_seat, on: %i[create update],
    if: -> { mission_team&.flight.present? && (previously_new_record? || saved_change_to_vehicle_id?) }

  def ensure_pilot_seat
    pilot = mission_slots.find_by(role: "pilot") ||
      mission_slots.create!(role: "pilot", title: PILOT_TITLE, position: -1)

    seat_owner(pilot)
  end

  def flight
    mission_team&.flight
  end

  default_scope -> { order(position: :asc) }

  FILTER_ATTRIBUTES = %i[classification foci min_size max_size min_crew min_cargo].freeze

  # Matched against a ship's own by equality, so a slot has to be spelled the
  # way the catalogue spells it.
  normalizes :classification, with: ->(value) { ::Model.normalize_value_for(:classification, value) }
  normalizes :foci, with: ->(value) { ::Model.ordered_foci(value) }

  validates :classification, inclusion: {in: ::Model::CLASSIFICATIONS}, allow_nil: true
  include FociList

  before_validation :take_model_from_vehicle

  validate :model_or_filter_required
  validate :flight_ship_names_a_vehicle, if: -> { flight.present? && (new_record? || will_save_change_to_vehicle_id?) }
  validate :model_must_be_in_game
  validate :allowed_models_must_be_in_game

  def strict?
    model_id.present?
  end

  # A hand-picked set of models rather than criteria: the spot takes any one of
  # them, so a signup matches if its ship is in the list.
  def listed?
    mission_ship_models.any?
  end

  def filtered?
    FILTER_ATTRIBUTES.any? { |attr| self[attr].present? }
  end

  def display_title
    title.presence || (vehicle.name.presence if vehicle&.name_visible?) || model&.name ||
      I18n.t("labels.mission_ship.placeholder")
  end

  private def take_model_from_vehicle
    self.model_id = vehicle.model_id if vehicle.present? && will_save_change_to_vehicle_id?
  end

  private def flight_ship_names_a_vehicle
    return errors.add(:vehicle_id, :blank) if vehicle.blank?

    squadron = flight.fleet_squadron
    available = FleetSquadron.vehicle_ids_for(fleet_id: squadron.fleet_id, squadron_ids: [squadron.id])
    return errors.add(:vehicle_id, :not_in_squadron) unless !vehicle.wanted? && available.exists?(id: vehicle.id)

    taken = mission_team.mission_ships.where(vehicle_id:).where.not(id:).exists?
    errors.add(:vehicle_id, :taken) if taken
  end

  # The ship's owner flies it unless somebody is already listed for the seat.
  private def seat_owner(pilot)
    return if vehicle.blank? || pilot.mission_slot_candidates.exists?

    row = flight.fleet_squadron.fleet_squadron_memberships
      .joins(:fleet_membership)
      .find_by(fleet_memberships: {user_id: vehicle.user_id})
    return if row.blank?

    pilot.mission_slot_candidates.create(fleet_squadron_membership: row, vehicle:, position: 0)
  end

  private def model_or_filter_required
    return if strict? || listed? || filtered?

    errors.add(:base, :model_or_filter_required)
  end

  private def model_must_be_in_game
    return if model.blank?
    return if model.in_game?

    errors.add(:model_id, :must_be_in_game)
  end

  # The same bar the single model has to clear: a spot cannot ask for a ship that
  # is not in the game yet, however it names it.
  #
  # Read through the join rows rather than through allowed_models: a has_many
  # :through on an unsaved parent queries the database and so comes back empty,
  # which let a new spot list a concept ship unchecked.
  private def allowed_models_must_be_in_game
    return if mission_ship_models.map(&:model).compact.all?(&:in_game?)

    errors.add(:allowed_model_ids, :must_be_in_game)
  end
end

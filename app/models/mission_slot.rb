# frozen_string_literal: true

class MissionSlot < ApplicationRecord
  include SlotRole

  belongs_to :slottable, polymorphic: true, touch: true
  belongs_to :model_position, optional: true
  has_many :mission_slot_candidates, dependent: :destroy

  LEAD_TITLE = "Flight lead"

  attr_readonly :lead

  # A flight always has its lead, and each of its ships a pilot. Those seats go
  # only with the flight or the ship itself.
  before_destroy :keep_flight_lead
  before_destroy :keep_ship_pilot

  validates :title, presence: true
  validates :slottable_type, inclusion: {in: %w[MissionTeam MissionShip]}

  def mission
    slottable&.mission
  end

  def mission_team
    slottable.is_a?(MissionShip) ? slottable.mission_team : slottable
  end

  def flight
    mission_team&.flight
  end

  def fleet_id
    mission_team&.fleet_id
  end

  private def keep_ship_pilot
    return unless pilot? && slottable.is_a?(MissionShip) && flight.present?
    return if destroyed_by_association
    return if slottable.mission_slots.where(role: "pilot").where.not(id:).exists?

    errors.add(:base, :pilot_required)
    throw :abort
  end

  private def keep_flight_lead
    return unless lead? && flight.present?
    return if destroyed_by_association

    errors.add(:base, :lead_required)
    throw :abort
  end

  # The lead seat's name is the app's, in the reader's language; the stored
  # title is only the fallback for a reader with none.
  def display_title
    lead? ? I18n.t("labels.slots.lead", default: title) : title
  end

  def derived?
    model_position_id.present?
  end

  def position_type
    model_position&.position_type
  end
end

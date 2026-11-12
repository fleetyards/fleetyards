# frozen_string_literal: true

class MissionTeam < ApplicationRecord
  include BuiltFromSquadron
  include BuiltFromFlight

  belongs_to :mission, touch: true, optional: true
  belongs_to :fleet_squadron_flight, touch: true, optional: true, inverse_of: :mission_team
  has_many :mission_ships, dependent: :destroy
  has_many :mission_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true
  validate :has_one_owner

  default_scope -> { order(position: :asc) }

  # The template it belongs to, or the flight -- never both, never neither.
  def fleet_id
    mission&.fleet_id || fleet_squadron_flight&.fleet_squadron&.fleet_id
  end

  def flight
    fleet_squadron_flight
  end

  private def squadron_fleet_id
    fleet_id
  end

  private def has_one_owner
    return if mission_id.present? ^ fleet_squadron_flight_id.present?

    errors.add(:base, :one_owner)
  end
end

# frozen_string_literal: true

class MissionSlot < ApplicationRecord
  belongs_to :slottable, polymorphic: true, touch: true
  belongs_to :model_position, optional: true
  has_many :mission_slot_candidates, dependent: :destroy

  validates :title, presence: true
  validates :slottable_type, inclusion: {in: %w[MissionTeam MissionShip]}

  default_scope -> { order(position: :asc) }

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

  def derived?
    model_position_id.present?
  end

  def position_type
    model_position&.position_type
  end
end

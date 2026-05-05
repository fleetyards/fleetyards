# frozen_string_literal: true

class FleetEventSlot < ApplicationRecord
  belongs_to :slottable, polymorphic: true, touch: true
  belongs_to :model_position, optional: true
  belongs_to :source_slot, class_name: "MissionSlot", optional: true
  has_many :fleet_event_signups, dependent: :destroy

  validates :title, presence: true
  validates :slottable_type, inclusion: {in: %w[FleetEventTeam FleetEventShip]}

  default_scope -> { order(position: :asc) }

  def fleet_event
    case slottable
    when FleetEventTeam
      slottable.fleet_event
    when FleetEventShip
      slottable.fleet_event_team.fleet_event
    end
  end

  def derived?
    model_position_id.present?
  end

  def position_type
    model_position&.position_type
  end

  def active_signups
    fleet_event_signups.where.not(status: "withdrawn")
  end
end

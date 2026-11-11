# frozen_string_literal: true

class FleetEventTeam < ApplicationRecord
  include BuiltFromSquadron

  belongs_to :fleet_event, touch: true
  belongs_to :source_team, class_name: "MissionTeam", optional: true
  has_many :fleet_event_ships, dependent: :destroy
  has_many :fleet_event_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true

  default_scope -> { order(position: :asc) }

  private def squadron_fleet_id
    fleet_event&.fleet_id
  end
end

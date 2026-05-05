# frozen_string_literal: true

class FleetEventTeam < ApplicationRecord
  belongs_to :fleet_event, touch: true
  belongs_to :source_team, class_name: "MissionTeam", optional: true
  has_many :fleet_event_ships, dependent: :destroy
  has_many :fleet_event_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true

  default_scope -> { order(position: :asc) }
end

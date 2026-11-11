# frozen_string_literal: true

class MissionTeam < ApplicationRecord
  include BuiltFromSquadron

  belongs_to :mission, touch: true
  has_many :mission_ships, dependent: :destroy
  has_many :mission_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true

  default_scope -> { order(position: :asc) }

  private def squadron_fleet_id
    mission&.fleet_id
  end
end

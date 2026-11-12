# frozen_string_literal: true

class FleetEventTeam < ApplicationRecord
  include BuiltFromSquadron
  include BuiltFromFlight

  belongs_to :fleet_event, touch: true
  belongs_to :source_team, class_name: "MissionTeam", optional: true
  has_many :fleet_event_ships, dependent: :destroy
  has_many :fleet_event_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true

  # Members a flight listed for its slots are offered them once the copy is
  # committed -- or, on an event that is not open yet, when it opens.
  after_create_commit :invite_flight_candidates

  private def invite_flight_candidates
    copied_flight_slots.each { |slot| FleetEvents::SlotInvites.new(slot).offer! }
  end

  default_scope -> { order(position: :asc) }

  private def squadron_fleet_id
    fleet_event&.fleet_id
  end
end

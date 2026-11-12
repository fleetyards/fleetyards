# frozen_string_literal: true

# A squadron's standing lineup: the ships it flies, the seats on them and who
# usually fills each seat. Picking one on an event or template team copies the
# lineup in; the copy is the team's own from then on.
#
# The ships and slots live on a template team the flight owns, so a flight is
# edited, validated and copied with exactly the machinery a template is.
class FleetSquadronFlight < ApplicationRecord
  belongs_to :fleet_squadron, touch: true

  has_one :mission_team, dependent: :destroy, inverse_of: :fleet_squadron_flight

  has_many :sourced_fleet_event_teams, class_name: "FleetEventTeam", foreign_key: :source_flight_id,
    inverse_of: :source_flight, dependent: nil
  has_many :sourced_mission_teams, class_name: "MissionTeam", foreign_key: :source_flight_id,
    inverse_of: :source_flight, dependent: nil

  validates :name,
    presence: true,
    length: {maximum: 255},
    uniqueness: {case_sensitive: false, scope: :fleet_squadron_id}

  validates :description, length: {maximum: 5000}, allow_blank: true

  default_scope -> { order(position: :asc, created_at: :asc) }

  before_create :append_to_squadron
  after_create :create_team!
  after_update :rename_team, if: :saved_change_to_name?

  delegate :fleet, to: :fleet_squadron

  def team
    mission_team || create_team!
  end

  private def create_team!
    create_mission_team!(title: name, position: 0).tap do |team|
      team.mission_slots.create!(lead: true, title: MissionSlot::LEAD_TITLE, position: 0)
    end
  end

  private def rename_team
    mission_team&.update!(title: name)
  end

  private def append_to_squadron
    return if fleet_squadron.blank?

    self.position = (fleet_squadron.fleet_squadron_flights.unscope(:order).maximum(:position) || -1) + 1
  end
end

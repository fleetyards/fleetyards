# frozen_string_literal: true

# A team on an event or event template that starts out as one of a squadron's
# flights: its ships, slots and the members listed for each slot are copied in
# when the team is created, and the team stands for the flight's squadron. The
# copy is the team's own from then on, so a flight changed later changes
# nothing here.
module BuiltFromFlight
  extend ActiveSupport::Concern

  included do
    belongs_to :source_flight, class_name: "FleetSquadronFlight", optional: true

    attr_readonly :source_flight_id

    validate :source_flight_belongs_to_the_fleet, on: :create

    before_validation :take_over_flight_details, on: :create
    after_create :copy_source_flight
  end

  private def take_over_flight_details
    return if source_flight.blank?

    self.fleet_squadron_id ||= source_flight.fleet_squadron_id
    self.title = source_flight.name if title.blank?
    self.description = source_flight.description.presence if description.blank?
  end

  private def copy_source_flight
    return if source_flight.blank?

    @flight_copier = MissionTeams::Copier.new(
      MissionTeams::Copier.preload(MissionTeam.where(id: source_flight.team.id)).first,
      self
    )
    @flight_copier.copy!
  end

  private def copied_flight_slots
    @flight_copier&.copied_slots || []
  end

  private def source_flight_belongs_to_the_fleet
    return if source_flight_id.blank?
    return errors.add(:source_flight, :not_in_fleet) if source_flight.blank?

    fleet_id = squadron_fleet_id
    return errors.add(:source_flight, :not_in_fleet) if fleet_id.present? && source_flight.fleet_squadron.fleet_id != fleet_id
    return if source_flight.fleet_squadron.flights_enabled?

    errors.add(:source_flight, :flights_disabled)
  end
end

# frozen_string_literal: true

# A squadron's flights are read by everyone who can see the squadron and
# arranged by whoever manages its roster -- the people who decide who flies
# with whom.
class FleetSquadronFlightPolicy < FleetBasePolicy
  authorize :fleet_squadron, optional: true

  def index?
    accepted_fleet_membership.present?
  end

  alias_rule :show?, to: :index?

  def create?
    squadron = record.try(:fleet_squadron) || fleet_squadron
    return false if squadron.blank?

    allowed_to?(:create?, FleetSquadronMembership.new(fleet_squadron: squadron), with: FleetSquadronMembershipPolicy)
  end

  alias_rule :update?, :destroy?, :sort?, to: :create?
end

# frozen_string_literal: true

# An alliance is answered for a fleet rather than by a person, so every rule
# here is two questions: does the acting fleet stand in this alliance, and does
# this member hold the privilege to act for it.
#
# `fleet` is the fleet being acted *for* -- the one whose route this is -- and
# the privileges default to `fleet:manage`, because committing the fleet's
# ships, stats and roster to another organisation is not an officer's call.
class FleetAlliancePolicy < FleetBasePolicy
  def index?
    has_access?(["fleet:allies:manage", "fleet:allies:read"])
  end

  def show?
    index?
  end

  def create?
    has_access?(["fleet:allies:manage", "fleet:allies:create"])
  end

  def accept?
    manage? && record.answerable_by?(fleet)
  end

  def decline?
    accept?
  end

  def ignore?
    accept?
  end

  def destroy?
    return false unless has_access?(["fleet:allies:manage", "fleet:allies:delete"])

    record.cancellable_by?(fleet) || (record.accepted? && record.involves?(fleet))
  end

  private def manage?
    has_access?(["fleet:allies:manage"])
  end

  private def has_access?(privileges)
    accepted_fleet_membership&.has_access?(["fleet:manage"] + privileges) || false
  end
end

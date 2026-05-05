# frozen_string_literal: true

class FleetEventSignupPolicy < FleetBasePolicy
  authorize :fleet_event, optional: true

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:read"])
  end

  alias_rule :update?, to: :create?

  # Admin-side management: reassigning slots, approving pending signups,
  # kicking members. Allowed for fleet event-managers, the event creator,
  # or per-event admins/moderators.
  def manage?
    return true if event_admin_or_moderator?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage"])
  end

  def destroy?
    return true if creator?
    return true if event_admin_or_moderator?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage"])
  end

  params_filter do |params|
    params.permit(:status, :vehicle_id, :notes)
  end

  private def creator?
    record.respond_to?(:fleet_membership_id) &&
      accepted_fleet_membership &&
      record.fleet_membership_id == accepted_fleet_membership.id
  end

  private def event_admin_or_moderator?
    target_event = record.try(:fleet_event) || fleet_event
    target_event&.event_moderator_or_admin?(user)
  end

  private def fleet_membership
    record_fleet_id =
      record.try(:fleet_event)&.fleet_id ||
      record.try(:fleet_id) ||
      fleet_event&.fleet_id ||
      fleet&.id

    return unless record_fleet_id

    user&.fleet_memberships&.find_by(fleet_id: record_fleet_id)
  end
end

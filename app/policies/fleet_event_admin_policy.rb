# frozen_string_literal: true

class FleetEventAdminPolicy < FleetBasePolicy
  authorize :fleet_event, optional: true

  def index?
    target = target_event
    return false unless target

    return true if target.created_by_id == user&.id
    return true if target.event_admin?(user)
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage"])
  end

  def create?
    target = target_event
    return false unless target

    return true if target.created_by_id == user&.id
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage"])
  end

  alias_rule :destroy?, :update?, to: :create?

  params_filter do |params|
    params.permit(:user_id, :role)
  end

  private def target_event
    record.try(:fleet_event) || (record.is_a?(::FleetEvent) ? record : nil) || fleet_event
  end

  private def fleet_membership
    target = target_event
    return unless target

    user&.fleet_memberships&.find_by(fleet_id: target.fleet_id)
  end
end

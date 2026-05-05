# frozen_string_literal: true

class FleetEventSlotPolicy < FleetBasePolicy
  authorize :fleet_event, optional: true

  def create?
    can_manage_event?
  end

  alias_rule :update?, :destroy?, :sort?, to: :create?

  params_filter do |params|
    params.permit(:title, :description, :model_position_id, :signup_approval)
  end

  private def can_manage_event?
    target_event = record_event
    return false unless target_event

    return true if target_event.event_admin?(user)

    membership = user&.fleet_memberships&.find_by(fleet_id: target_event.fleet_id)
    return false unless membership&.accepted?

    membership.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:update"])
  end

  private def record_event
    case record
    when FleetEventSlot then record.fleet_event
    when FleetEventShip then record.fleet_event_team&.fleet_event
    when FleetEventTeam then record.fleet_event
    when FleetEvent then record
    else fleet_event
    end
  end
end

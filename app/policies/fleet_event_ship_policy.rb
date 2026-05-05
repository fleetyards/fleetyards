# frozen_string_literal: true

class FleetEventShipPolicy < FleetBasePolicy
  authorize :fleet_event, optional: true

  def create?
    can_manage_event?
  end

  alias_rule :update?, :destroy?, :sort?, to: :create?

  params_filter do |params|
    params.permit(
      :title, :description, :model_id, :strict,
      :classification, :focus, :min_size, :max_size, :min_crew, :min_cargo
    )
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
    if record.respond_to?(:fleet_event_team)
      record.fleet_event_team&.fleet_event
    end || record.try(:fleet_event) ||
      (record.is_a?(FleetEvent) ? record : nil) ||
      fleet_event
  end
end

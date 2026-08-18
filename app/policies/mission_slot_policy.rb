# frozen_string_literal: true

class MissionSlotPolicy < FleetBasePolicy
  authorize :mission, optional: true

  def create?
    can_update_mission?
  end

  alias_rule :update?, :destroy?, :sort?, to: :create?

  params_filter do |params|
    params.permit(:title, :description, :slottable_type, :slottable_id)
  end

  private def can_update_mission?
    membership = user&.fleet_memberships&.find_by(fleet_id: mission_fleet_id)
    return false unless membership&.accepted?

    membership.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:update"])
  end

  private def mission_fleet_id
    record_mission&.fleet_id || mission&.fleet_id
  end

  private def record_mission
    record.try(:mission) || (record.is_a?(Mission) ? record : nil)
  end
end

class FleetMembershipPolicy < FleetBasePolicy
  alias_rule :accept_invitation?, :decline_invitation?, to: :show?

  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:read"])
  end

  def show?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:read"]) ||
      record.user_id == user.id
  end

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:create"])
  end

  def accept_request?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  end

  def decline_request?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  end

  def promote?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  end

  def demote?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  end

  def update?
    record.try(:user_id) && record.user_id == user.id
  end

  def destroy?
    (accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:destroy"]) && record.id != fleet_membership&.id) ||
      (record.id == fleet_membership&.id && !fleet_membership&.fleet_role&.permanent?)
  end

  params_filter do |params|
    allowed_params = []

    if fleet_membership.present?
      allowed_params << [:primary, :ships_filter, :hangar_group_id]
    end

    params.permit(*allowed_params.flatten)
  end
end

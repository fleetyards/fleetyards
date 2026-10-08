class FleetInviteUrlPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:invites:manage", "fleet:invites:read"])
  end

  def create?
    accepted_fleet_membership&.has_access?(FleetMembership::CAPABILITY_PRIVILEGES[:create_invites])
  end

  def use?
    user.present?
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:invites:manage", "fleet:invites:delete"])
  end

  relation_scope do |relation|
    relation.where(fleet_id: user.fleet_ids)
  end

  params_filter do |params|
    params.permit(:limit, :expires_after_minutes)
  end
end

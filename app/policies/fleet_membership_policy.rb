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

  # Without fleet:manage a caller never changes its own rank and never moves
  # anyone above its own rank. Otherwise an Officer could promote itself into
  # the permanent Admin role and then demote the admins.
  def promote?
    return false unless change_ranks?
    return true if manages_fleet?

    !own_membership? && not_above_caller?(record.next_fleet_role)
  end

  def demote?
    return false unless change_ranks?
    return true if manages_fleet?

    !own_membership? && not_above_caller?(record.fleet_role)
  end

  alias_rule :remind_verification?, to: :health?

  # Lists members as well as offering to act on them, so it takes both.
  def health?
    index? && accepted_fleet_membership.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  end

  # Distinct from `update?`, which is the self-service rule the membership
  # endpoint uses. A nickname is set on someone else, so it is gated on the
  # same privilege as promote/demote rather than on owning the record.
  def update_nickname?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  end

  def update?
    record.try(:user_id) && record.user_id == user.id
  end

  def destroy?
    (accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:destroy"]) && record.id != fleet_membership&.id) ||
      (record.id == fleet_membership&.id && !fleet_membership&.fleet_role&.permanent?)
  end

  params_filter(:update_nickname) do |params|
    params.permit(:nickname)
  end

  params_filter do |params|
    allowed_params = []

    if fleet_membership.present?
      allowed_params << [:primary, :ships_filter, :hangar_group_id, :blueprints_filter]
    end

    params.permit(*allowed_params.flatten)
  end

  private def change_ranks?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"]) || false
  end

  private def manages_fleet?
    accepted_fleet_membership.has_access?(["fleet:manage"])
  end

  private def own_membership?
    record.user_id == user.id
  end

  private def not_above_caller?(role)
    return false if role.blank?

    ranked = record.fleet.fleet_roles.ranked.to_a
    caller_index = ranked.index(accepted_fleet_membership.fleet_role)
    role_index = ranked.index(role)
    caller_index.present? && role_index.present? && role_index >= caller_index
  end
end

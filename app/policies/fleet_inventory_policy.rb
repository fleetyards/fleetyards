# frozen_string_literal: true

class FleetInventoryPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(FleetInventory::READ_PRIVILEGES)
  end

  def show?
    return false unless index?

    record.visible_to?(accepted_fleet_membership)
  end

  def create?
    accepted_fleet_membership&.has_access?([*FleetInventory::OFFICER_PRIVILEGES, "fleet:inventories:create"])
  end

  def update?
    return false unless accepted_fleet_membership&.has_access?([*FleetInventory::OFFICER_PRIVILEGES, "fleet:inventories:update"])

    record.visible_to?(accepted_fleet_membership)
  end

  def destroy?
    return false unless accepted_fleet_membership&.has_access?([*FleetInventory::OFFICER_PRIVILEGES, "fleet:inventories:delete"])

    record.visible_to?(accepted_fleet_membership)
  end

  # Visibility alone: which of the fleet's inventories are not hidden from this
  # member. This is the SQL half of `FleetInventory#visible_to?`, and the two
  # are kept together by FleetInventoryPolicyTest, which asserts they agree
  # over the same set.
  #
  # Deliberately without the read gate. A lookup that precedes its own
  # `authorize!` uses this, and the privilege lists are independent of each
  # other -- a role may carry `fleet:inventories:update` without `:read`, and
  # gating the lookup on reading would answer 404 for a write the record rule
  # allows.
  #
  # Needs the fleet context. Every caller is scoped to one fleet already, and
  # reading the fleet off the relation instead would quietly answer `none` for
  # a caller that forgot to pass it rather than saying so.
  relation_scope(:visible) do |relation|
    require_fleet!

    membership = accepted_fleet_membership

    if membership.blank?
      relation.none
    elsif membership.has_access?(FleetInventory::OFFICER_PRIVILEGES)
      relation
    else
      relation.where(visibility: :members_only)
        .or(relation.where(visibility: :officers_only, managed_by: membership.user_id))
        .or(relation.merge(FleetInventory.restricted_to_squadrons_of(membership)))
    end
  end

  # What a member may see listed: the same visibility behind the read gate
  # `index?` applies, so the scope and `show?` answer alike and a list cannot
  # be served to a role carrying no inventory access at all.
  relation_scope do |relation|
    require_fleet!

    next relation.none unless index?

    apply_scope(relation, type: :active_record_relation, name: :visible)
  end

  # Both scopes need the fleet context, and neither may quietly answer `none`
  # without it: a caller that forgot to pass it would read as "you may see
  # nothing here" rather than as the mistake it is.
  private def require_fleet!
    raise ArgumentError, "FleetInventoryPolicy's relation scopes need a fleet context" if fleet.blank?
  end

  params_filter do |params|
    params.permit(:name, :description, :managed_by, :visibility, :location, :image, :image_preset,
      fleet_squadron_ids: [])
  end
end

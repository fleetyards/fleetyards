# frozen_string_literal: true

class FleetInventoryPolicy < FleetBasePolicy
  READ_PRIVILEGES = [*FleetInventory::OFFICER_PRIVILEGES, "fleet:inventories:read"].freeze

  def index?
    accepted_fleet_membership&.has_access?(READ_PRIVILEGES)
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

  # Needs the fleet context. Every caller is scoped to one fleet already, and
  # reading the fleet off the relation instead would quietly answer `none` for
  # a caller that forgot to pass it rather than saying so.
  relation_scope do |relation|
    raise ArgumentError, "FleetInventoryPolicy's relation scope needs a fleet context" if fleet.blank?

    membership = accepted_fleet_membership

    # The read gate first, the same one `index?` applies. Without it the scope
    # answered for a member whose role carries no inventory access at all,
    # while `show?` refused them -- the two halves disagreeing in exactly the
    # way this scope exists to avoid.
    if membership.blank? || !membership.has_access?(READ_PRIVILEGES)
      relation.none
    elsif membership.has_access?(FleetInventory::OFFICER_PRIVILEGES)
      relation
    else
      # The SQL half of `FleetInventory#visible_to?`. The two are kept together
      # by FleetInventoryPolicyTest, which asserts the scope and the record
      # check agree over the same set.
      relation.where(visibility: :members_only).or(relation.where(managed_by: membership.user_id))
    end
  end

  params_filter do |params|
    params.permit(:name, :description, :managed_by, :visibility, :location, :image, :image_preset)
  end
end

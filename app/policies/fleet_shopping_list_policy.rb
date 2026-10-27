# frozen_string_literal: true

class FleetShoppingListPolicy < FleetBasePolicy
  alias_rule :copy?, to: :show?

  def index?
    accepted_fleet_membership&.has_access?(FleetShoppingList::READ_PRIVILEGES)
  end

  def show?
    return false unless index?

    record.visible_to?(accepted_fleet_membership)
  end

  # The record as it would be saved, so a writer cannot pick a visibility
  # that hides the list from them.
  def create?
    return false unless accepted_fleet_membership&.has_access?([*FleetShoppingList::OFFICER_PRIVILEGES, "fleet:shopping_lists:create"])

    record.visible_to?(accepted_fleet_membership)
  end

  def update?
    return false unless accepted_fleet_membership&.has_access?([*FleetShoppingList::OFFICER_PRIVILEGES, "fleet:shopping_lists:update"])

    record.visible_to?(accepted_fleet_membership)
  end

  def destroy?
    return false unless accepted_fleet_membership&.has_access?([*FleetShoppingList::OFFICER_PRIVILEGES, "fleet:shopping_lists:delete"])

    record.visible_to?(accepted_fleet_membership)
  end

  # The SQL half of `FleetShoppingList#visible_to?`, without the read gate: a
  # role may carry `:update` without `:read`, and the lookup before a write
  # must not answer 404 for a write the record rule allows.
  relation_scope(:visible) do |relation|
    require_fleet!

    membership = accepted_fleet_membership

    if membership.blank?
      relation.none
    elsif membership.has_access?(FleetShoppingList::OFFICER_PRIVILEGES)
      relation
    else
      relation.where(visibility: :members_only)
        .or(relation.merge(FleetShoppingList.restricted_to_squadrons_of(membership)))
    end
  end

  relation_scope do |relation|
    require_fleet!

    next relation.none unless index?

    apply_scope(relation, type: :active_record_relation, name: :visible)
  end

  private def require_fleet!
    raise ArgumentError, "FleetShoppingListPolicy's relation scopes need a fleet context" if fleet.blank?
  end

  params_filter do |params|
    params.permit(:name, :description, :visibility, fleet_squadron_ids: [])
  end
end

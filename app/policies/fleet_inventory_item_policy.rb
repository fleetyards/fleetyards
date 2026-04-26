# frozen_string_literal: true

class FleetInventoryItemPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:inventories:read"])
  end

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:inventories:update"])
  end

  alias_rule :update?, :destroy?, to: :create?

  params_filter do |params|
    if record.try(:persisted?)
      params.permit(:name, :notes, :category)
    else
      params.permit(:name, :category, :quantity, :unit, :entry_type, :quality, :member_id, :image, :notes, :item_type, :item_id)
    end
  end
end

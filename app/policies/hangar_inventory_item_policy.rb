# frozen_string_literal: true

class HangarInventoryItemPolicy < ApplicationPolicy
  alias_rule :create?, :update?, :destroy?, to: :show?

  def index?
    user.present?
  end

  def show?
    user&.id == record.hangar_inventory&.user_id
  end

  params_filter do |params|
    if record.try(:persisted?)
      params.permit(:name, :notes, :category, :unit)
    else
      params.permit(:name, :category, :quantity, :unit, :entry_type, :quality, :image, :notes, :item_type, :item_id)
    end
  end
end

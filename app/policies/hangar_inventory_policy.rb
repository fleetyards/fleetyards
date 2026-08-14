# frozen_string_literal: true

# Rules for inventories a user holds themselves. Inventory says nothing about
# who holds it, so callers name this policy explicitly rather than letting the
# record class pick one.
class HangarInventoryPolicy < ApplicationPolicy
  alias_rule :create?, :update?, :destroy?, to: :show?

  def index?
    user.present?
  end

  def show?
    user.present? && record.holder == user
  end

  relation_scope do |relation|
    relation.where(holder: user)
  end

  params_filter do |params|
    params.permit(:name, :description, :location, :image)
  end
end

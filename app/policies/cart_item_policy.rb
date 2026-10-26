# frozen_string_literal: true

class CartItemPolicy < ApplicationPolicy
  alias_rule :update?, :destroy?, to: :show?
  alias_rule :clear?, to: :index?

  def index?
    user.present?
  end

  def create?
    user.present? && record.cart&.user_id == user.id
  end

  def show?
    user.present? && record.cart&.user_id == user.id
  end

  relation_scope do |relation|
    relation.joins(:cart).where(carts: {user_id: user.id})
  end
end

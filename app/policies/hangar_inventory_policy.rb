# frozen_string_literal: true

class HangarInventoryPolicy < ApplicationPolicy
  alias_rule :create?, :update?, :destroy?, to: :show?

  def index?
    user.present?
  end

  def show?
    user&.id == record.user_id
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end

  params_filter do |params|
    params.permit(:name, :description, :location, :image)
  end
end

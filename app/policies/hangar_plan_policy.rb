# frozen_string_literal: true

class HangarPlanPolicy < ApplicationPolicy
  alias_rule :update?, :destroy?, to: :show?

  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def show?
    user.present? && record.user_id == user.id
  end

  def shared?
    record.shared?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end

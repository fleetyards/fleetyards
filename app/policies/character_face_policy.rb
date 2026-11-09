# frozen_string_literal: true

class CharacterFacePolicy < ApplicationPolicy
  alias_rule :update?, :destroy?, to: :manage?

  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def manage?
    user.present? && record.user_id == user.id
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end

# frozen_string_literal: true

class FeedbackPolicy < ApplicationPolicy
  alias_rule :reply?, to: :show?

  relation_scope do |relation|
    user.present? ? relation.where(user_id: user.id) : relation.none
  end

  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def show?
    user.present? && record.user_id == user.id
  end
end

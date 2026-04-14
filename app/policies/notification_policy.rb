# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  alias_rule :destroy?, :update?, to: :show?

  def show?
    user.present?
  end

  def read_all?
    user.present?
  end

  def destroy_all?
    user.present?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end

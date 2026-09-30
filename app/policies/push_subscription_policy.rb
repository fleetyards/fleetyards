# frozen_string_literal: true

class PushSubscriptionPolicy < ApplicationPolicy
  alias_rule :index?, :create?, to: :show?

  def show?
    user.present?
  end

  def destroy?
    user.present? && record.user_id == user.id
  end
end

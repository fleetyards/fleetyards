# frozen_string_literal: true

class NotificationPreferencePolicy < ApplicationPolicy
  alias_rule :index?, :update?, to: :show?

  def show?
    user.present?
  end
end

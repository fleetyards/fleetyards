# frozen_string_literal: true

class OmniauthConnectionPolicy < ApplicationPolicy
  def destroy?
    user.present? && record.user_id == user.id
  end
end

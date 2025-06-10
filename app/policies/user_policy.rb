class UserPolicy < ApplicationPolicy
  default_rule :manage?

  def me?
    user.present?
  end

  def manage?
    user&.id == record.id
  end
end

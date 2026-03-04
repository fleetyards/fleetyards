module Admin
  class AdminUserPolicy < ApplicationPolicy
    default_rule :manage?

    def me?
      user.present?
    end

    def manage?
      user&.super_admin? || user&.id == record.id
    end

    def index?
      user&.super_admin?
    end

    def create?
      user&.super_admin?
    end

    def destroy?
      user&.super_admin? && user&.id != record.id
    end
  end
end

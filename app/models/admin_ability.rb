# frozen_string_literal: true

class AdminAbility
  include CanCan::Ability

  def initialize(admin_user)
    return if admin_user.blank?

    can :manage, :all
  end
end

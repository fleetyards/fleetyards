# frozen_string_literal: true

class AdminAbility
  include CanCan::Ability

  def initialize(admin_user)
    return if admin_user.blank?

    can :read, AdminUser, id: admin_user.id

    can :manage, :all if admin_user.super_admin?

    can :read, :admin_stats if admin_user.access_to?(:stats)
    can :manage, Model if admin_user.access_to?(:models)
    can :manage, ModelModule if admin_user.access_to?(:model_modules)
    can :manage, ModelPaint if admin_user.access_to?(:model_paints)
    can :manage, Component if admin_user.access_to?(:components)
    can :manage, ItemPrice if admin_user.access_to?(:item_prices)
    can :manage, Manufacturer if admin_user.access_to?(:manufacturers)
    can :manage, Image if admin_user.access_to?(:images)
    can :manage, Fleet if admin_user.access_to?(:fleets)
    can :manage, User if admin_user.access_to?(:users)
    can :manage, Import if admin_user.access_to?(:imports)
    can :manage, Oauth::Application if admin_user.access_to?(:oauth_applications)
    can :manage, Vehicle if admin_user.access_to?(:vehicles)
  end
end

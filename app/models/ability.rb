class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    end

    if user.id.present?
      can :index, :hangar
      can [:add, :remove], UserShip, user_id: user.id
    end

    can :update, User, id: user.id
    can :index, :manufacturers
    can :show, Manufacturer, enabled: true
    can :index, :components
    can :show, Component, enabled: true
    can :index, :images
    can :index, :ships
    can [:show, :gallery], Ship, enabled: true
  end
end

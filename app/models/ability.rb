class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    end

    can :update, User, id: user.id
    can :index, :manufacturers
    can :index, :weapons
    can :show, Weapon, enabled: true
    can :index, :equipment
    can :show, Equipment, enabled: true
    can :index, :images
    can :index, :ships
    can [:show, :gallery], Ship, enabled: true
  end
end

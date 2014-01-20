class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :check, :worker
      can :update, :locales
      can :show, :backend
      can :reload, :ships
      can [:create, :update, :destroy], :setting
    end

    can :update, User, id: user.id
    can [:index], :weapons
    can [:index], :equipment
    can [:index, :show], :ships
  end
end

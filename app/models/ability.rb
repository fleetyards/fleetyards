class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :check, :worker
      can :update, :locales
      can :show, :dashboard
      can :reload, :ships
    end

    can :update, User, id: user.id
    can [:index, :show], :ships
  end
end

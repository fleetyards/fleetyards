class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    end

    can :update, User, id: user.id
    can [:index], :manufacturers
    can [:index], :weapons
    can [:index], :equipment
    can [:index, :show, :gallery], :ships
  end
end

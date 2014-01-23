class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    end

    can :update, User, id: user.id
    can [:index], :weapons
    can [:index], :equipment
    can [:index, :show], :ships
  end
end

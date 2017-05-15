# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :manage, :all if user.admin?

    can :show, :api
    can %i[index show], :api_ships

    if user.id.present?
      can :show, :hangar
      can %i[add remove], UserShip, user_id: user.id
    end

    can :update, User, id: user.id
  end
end

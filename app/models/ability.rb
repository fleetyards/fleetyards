# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :manage, :all if user.admin?

    can :read, [:manufacturers, Manufacturer]
    can :read, [:models, Model]
    can :read, [:components, Component]

    can :show, :api
    can %i[index show], :api_models
    can %i[index], :api_images
    can %i[show], :api_components
    can %i[index show join], :api_fleets

    return if user.id.blank?

    can :index, :api_hangar
    can :index, :api_my_fleets
    can %i[add remove], Vehicle, user_id: user.id
    can %i[read update], User, id: user.id
  end
end

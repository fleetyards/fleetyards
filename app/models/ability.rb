# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :manage, :all if user.admin?

    can :read, [:manufacturers, Manufacturer]
    can :read, [:models, Model]
    can :read, [:components, Component]

    can :check, :users

    can :show, :api
    can %i[index show], :api_models
    can %i[index], :api_images
    can %i[index], :api_trade_hubs
    can %i[index], :api_commodities
    can %i[index], :api_hangar_groups
    can %i[show create], :api_commodity_prices
    can %i[show], :api_components
    can %i[index show join], :api_fleets

    return if user.id.blank?

    can :index, :api_hangar
    can :index, :api_my_fleets
    can %i[create update destroy], Vehicle, user_id: user.id
    can %i[create update destroy], HangarGroup, user_id: user.id
    can %i[read update rsi_verify], User, id: user.id
  end
end

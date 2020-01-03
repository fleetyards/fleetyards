# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    guest_rules

    user_rules(user)

    admin_rules(user)
  end

  private def guest_rules
    can :read, [:manufacturers, Manufacturer]
    can :read, [:models, Model]
    can :read, [:components, Component]

    can :check, :users

    can :show, :api
    can :read, :api_stats
    can %i[index show], :api_models
    can %i[index], :api_manufacturers
    can %i[index show], :api_stations
    can %i[show index], :api_celestial_objects
    can %i[index show], :api_shops
    can %i[index], :api_shop_commodities
    can %i[show index], :api_starsystems
    can %i[index], :api_images
    can %i[index], :api_commodities
    can %i[index], :api_components
    can %i[index], :api_equipment
    can %i[index sort], :api_hangar_groups
    can %i[show create], :api_commodity_prices
    can %i[show], :api_components
    can %i[index], :api_roadmap
    can %i[index], :api_search
    can %i[index], :api_trade_routes
    can :read, :api_fleet

    can %i[read_public], :user
  end

  private def user_rules(user)
    return if user.id.blank?

    fleet_ids = user.fleets
                    .includes(:fleet_memberships)
                    .joins(:fleet_memberships)
                    .where(fleet_memberships: { role: %i[officer admin] })
                    .where.not(fleet_memberships: { accepted_at: nil })
                    .pluck(:id)

    can :index, :api_hangar
    can %i[accept update destroy], FleetMembership, user_id: user.id
    can %i[create update destroy], FleetMembership, fleet_id: fleet_ids
    can :create, Fleet
    can :show, Fleet, fleet_memberships: { user_id: user.id }
    cannot :show, Fleet, fleet_memberships: { user_id: user.id, accepted_at: nil }
    can %i[update destroy], Fleet, fleet_memberships: { user_id: user.id, role: :admin }
    can %i[create update destroy], Vehicle, user_id: user.id
    can %i[create update destroy], HangarGroup, user_id: user.id
    can %i[read update destroy], User, id: user.id
  end

  private def admin_rules(user)
    return if user.id.blank? || !user.admin?

    can :manage, :all
  end
end

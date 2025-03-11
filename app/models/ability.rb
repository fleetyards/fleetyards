# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    guest_rules

    user_rules(user)

    fleet_rules(user)
  end

  private def guest_rules
    can :read, [:manufacturers, Manufacturer]
    can :read, [:models, Model]
    can :read, [:components, Component]

    can :check, :api_users
    can :show, :api_features

    can :show, :api
    can :read, :api_stats
    can %i[index show], :api_models
    can %i[index], :api_manufacturers
    can %i[index], :api_images
    can %i[public], :api_hangar_groups
    can %i[read], :api_fleet
    can %i[filters], :api_hangar

    can %i[read_public], :api_user
  end

  private def user_rules(user)
    return if user.id.blank?

    can %i[check_serial], :api_vehicles
    can %i[index sort], :api_hangar_groups
    can %i[show update destroy index destroy_all create_bulk update_bulk destroy_bulk], :api_hangar
    can %i[read create update destroy], Vehicle, user_id: user.id
    can %i[create update destroy], HangarGroup, user_id: user.id
    can %i[read confirm_access update destroy], User, id: user.id
    can %i[index], :api_oauth_applications
    can %i[read create update destroy], Oauth::Application, owner_id: user.id, owner_type: "User"
    can %i[read create destroy], :oauth_authorizations
  end

  private def fleet_rules(user)
    return if user.id.blank?

    admin_and_officer_fleet_ids = user.fleets
      .includes(:fleet_memberships)
      .joins(:fleet_memberships)
      .where(fleet_memberships: {role: %i[officer admin], aasm_state: :accepted})
      .pluck(:id)
    admin_fleet_ids = user.fleets
      .includes(:fleet_memberships)
      .joins(:fleet_memberships)
      .where(fleet_memberships: {role: :admin, aasm_state: :accepted})
      .pluck(:id)

    can %i[check invites], :api_fleet
    can :create, Fleet
    can %i[exists], :api_fleet_invite_url
    can %i[show create destroy], FleetInviteUrl, fleet_id: admin_and_officer_fleet_ids
    can %i[show accept_invitation decline_invitation create_by_invite update destroy], FleetMembership, user_id: user.id
    can %i[create accept_request decline_request], FleetMembership, fleet_id: admin_and_officer_fleet_ids
    can %i[update destroy demote promote], FleetMembership, fleet_id: admin_fleet_ids
    can :show, Fleet, fleet_memberships: {user_id: user.id}
    cannot :show, Fleet, fleet_memberships: {user_id: user.id, aasm_state: %i[created invited requested declined]}
    can %i[update destroy], Fleet, fleet_memberships: {user_id: user.id, role: :admin}
  end
end

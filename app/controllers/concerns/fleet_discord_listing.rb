# frozen_string_literal: true

# What the fleet settings page picks Discord channels and roles from: a
# listing of the fleet's bound guild, readable by a signed-in user or an
# OAuth token with fleet access.
module FleetDiscordListing
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: []
    before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
      unless: :user_signed_in?,
      only: %i[index]

    before_action :set_fleet
  end

  private def guild_id
    @fleet.fleet_notification_setting&.discord_guild_id
  end

  private def set_fleet
    @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
    authorize! @fleet, to: :show?
  end
end

# frozen_string_literal: true

module Api
  module V1
    class FleetDiscordChannelsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]

      before_action :set_fleet

      def index
        authorize! with: FleetDiscordChannelPolicy, context: {fleet: @fleet}

        @result = ::Discord::GuildChannels.new(@fleet.fleet_notification_setting&.discord_guild_id).fetch
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end

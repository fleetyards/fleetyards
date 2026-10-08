# frozen_string_literal: true

module Api
  module V1
    class FleetDiscordRolesController < ::Api::BaseController
      include FleetDiscordListing

      def index
        authorize! with: FleetDiscordRolePolicy, context: {fleet: @fleet}

        @result = ::Discord::GuildRoles.new(guild_id).fetch
      end
    end
  end
end

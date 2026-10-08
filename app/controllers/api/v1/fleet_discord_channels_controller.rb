# frozen_string_literal: true

module Api
  module V1
    class FleetDiscordChannelsController < ::Api::BaseController
      include FleetDiscordListing

      def index
        authorize! with: FleetDiscordChannelPolicy, context: {fleet: @fleet}

        @result = ::Discord::GuildChannels.new(guild_id).fetch
      end
    end
  end
end

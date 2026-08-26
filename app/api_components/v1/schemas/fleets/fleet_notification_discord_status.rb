# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetNotificationDiscordStatus
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            ok: {type: :boolean},
            code: {type: :string},
            message: {type: :string},
            guildId: {type: :string},
            guildName: {type: :string},
            status: {type: :integer},
            installUrl: {type: :string}
          }
        })
      end
    end
  end
end

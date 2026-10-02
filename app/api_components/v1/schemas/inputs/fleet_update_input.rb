# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fid: {type: [:string, :null]},
            name: {type: [:string, :null]},
            logo: {type: [:string, :null]},
            removeLogo: {type: :boolean},
            backgroundImage: {type: [:string, :null], format: :binary},
            # A cover per contract kind. Signed ids, like the logo above.
            transportContractCover: {type: [:string, :null]},
            procurementContractCover: {type: [:string, :null]},
            craftingContractCover: {type: [:string, :null]},
            removeBackground: {type: :boolean},
            description: {type: [:string, :null]},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            alliesFleet: {type: :boolean},
            alliesFleetStats: {type: :boolean},
            alliesFleetMembers: {type: :boolean},
            squadronsEnabled: {type: :boolean},
            listed: {type: :boolean},
            alignment: ::V1::Schemas::Enums::NullableFleetAlignmentEnum,
            homepage: {type: [:string, :null]},
            headquarters: {type: [:string, :null]},
            headquartersLocationId: {type: [:string, :null], format: :uuid},
            rsiSid: {type: [:string, :null]},
            discord: {type: [:string, :null]},
            ts: {type: [:string, :null]},
            youtube: {type: [:string, :null]},
            twitch: {type: [:string, :null]},
            guilded: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end

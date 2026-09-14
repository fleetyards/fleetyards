# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractCrewUser
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string},
            avatar: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[id username]
        })
      end
    end
  end
end

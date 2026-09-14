# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # A crew member as a board shows one: a face and a name. Not the nullable
      # `FleetContractCrewUser`, which describes an assignment's user and so has
      # to allow the seat a departed member left behind.
      class FleetContractBoardMember
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
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

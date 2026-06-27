# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminFleetRole
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            permanent: {type: :boolean},
            rank: {type: :string}
          },
          additionalProperties: false,
          required: %w[id name permanent]
        })
      end
    end
  end
end

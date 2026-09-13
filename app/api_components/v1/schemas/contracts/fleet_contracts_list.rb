# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractsList
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContract
            },
            meta: ::Shared::V1::Schemas::Meta
          },
          required: %w[items meta]
        })
      end
    end
  end
end

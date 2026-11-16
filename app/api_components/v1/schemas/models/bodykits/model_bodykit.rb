# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Bodykits
        class ModelBodykit
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              slot: {type: :string, description: "The hardpoint the body kit fits (its sc_name)"},
              stock: {type: :boolean, description: "Whether the hull comes with this body kit from the factory"},
              component: ::V1::Schemas::Loadouts::LoadoutComponentRef
            },
            additionalProperties: false,
            required: %w[slot stock component]
          })
        end
      end
    end
  end
end

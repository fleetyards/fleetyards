# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module CargoHolds
          # Only id and name are guaranteed, so this is not ModelRef.
          class AdminCargoHoldParent
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                name: {type: :string},
                slug: {type: :string}
              },
              required: %w[id name]
            })
          end
        end
      end
    end
  end
end

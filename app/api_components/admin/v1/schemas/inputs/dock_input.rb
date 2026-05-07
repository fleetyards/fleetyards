# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class DockInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string, nullable: true},
              dockType: {type: :string},
              shipSize: {type: :string},
              group: {type: :string, nullable: true},
              length: {type: :number, nullable: true},
              beam: {type: :number, nullable: true},
              height: {type: :number, nullable: true},
              minShipSize: {type: :integer, nullable: true},
              maxShipSize: {type: :integer, nullable: true},
              modelId: {type: :string, format: :uuid, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end

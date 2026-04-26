# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInventoryCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: :string, nullable: true},
            managedBy: {type: :string, format: :uuid, nullable: true},
            visibility: {type: :string, enum: %w[members_only officers_only]},
            location: {type: :string, nullable: true},
            image: {type: :string, nullable: true}
          },
          required: %w[name],
          additionalProperties: false
        })
      end
    end
  end
end

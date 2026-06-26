# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class DestroyedFleet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            name: {type: :string},
            slug: {type: :string},
            description: {type: :string},
            publicFleet: {type: :boolean},
            createdBy: {type: :string, format: :uuid},
            source: {type: :string, enum: %w[discarded purged]},
            destroyedAt: {type: :string, format: "date-time"},
            destroyedBy: {type: :string},
            restorable: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[id fid name slug publicFleet source destroyedAt restorable]
        })
      end
    end
  end
end

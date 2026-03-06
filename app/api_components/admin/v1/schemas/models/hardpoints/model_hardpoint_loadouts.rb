# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Hardpoints
          class ModelHardpointLoadouts < ::Shared::V1::Schemas::BaseList
            include Rswag::SchemaComponents::Component

            schema({
              properties: {
                items: {type: :array, items: {"$ref": "#/components/schemas/ModelHardpointLoadout"}}
              },
              required: %w[items]
            })
          end
        end
      end
    end
  end
end

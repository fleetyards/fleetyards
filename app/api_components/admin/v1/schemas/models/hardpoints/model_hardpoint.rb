# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Hardpoints
          class ModelHardpoint < ::V1::Schemas::Models::Hardpoints::ModelHardpoint
            include Rswag::SchemaComponents::Component

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid}
              },
              additionalProperties: false,
              required: %w[id]
            })
          end
        end
      end
    end
  end
end

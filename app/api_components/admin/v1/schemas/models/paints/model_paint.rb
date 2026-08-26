# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Paints
          class ModelPaint < ::V1::Schemas::Models::Paints::ModelPaint
            include OpenapiRuby::Components::Base

            schema({
              properties: {
                hidden: {type: :boolean},
                active: {type: :boolean},
                onSale: {type: :boolean},
                pledgePrice: {type: :number},
                productionStatus: {type: :string},
                productionNote: {type: :string},
                model: {"$ref": "#/components/schemas/Model"},
                media: AdminModelPaintMedia
              },
              required: %w[hidden active media model]
            })
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Modules
          class ModelModule < ::V1::Schemas::Models::Modules::ModelModule
            include SchemaConcern

            schema({
              properties: {
                model: {"$ref": "#/components/schemas/Model"},
              },
              required: %w[model]
            })
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Paints
          class ModelPaint < ::V1::Schemas::Models::Paints::ModelPaint
            include SchemaConcern

            schema({
              properties: {}
            })
          end
        end
      end
    end
  end
end

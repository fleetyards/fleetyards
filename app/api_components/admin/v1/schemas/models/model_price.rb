# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class ModelPrice < ::V1::Schemas::Models::ModelPrice
          include SchemaConcern

          schema({
            properties: {}
          })
        end
      end
    end
  end
end

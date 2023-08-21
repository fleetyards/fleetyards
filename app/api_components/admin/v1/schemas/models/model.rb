# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class Model < ::V1::Schemas::Models::Model
          include SchemaConcern

          schema({
            properties: {}
          })
        end
      end
    end
  end
end

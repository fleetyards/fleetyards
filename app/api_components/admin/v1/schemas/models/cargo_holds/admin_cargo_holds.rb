# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module CargoHolds
          class AdminCargoHolds < ::Shared::V1::Schemas::BaseList
            include OpenapiRuby::Components::Base

            schema({
              properties: {
                items: {type: :array, items: ::Admin::V1::Schemas::Models::CargoHolds::AdminCargoHold}
              },
              required: %w[items]
            })
          end
        end
      end
    end
  end
end

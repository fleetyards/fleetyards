# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Owners
        class ModelOwners
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              vehicles: {type: :array, items: ::V1::Schemas::Models::Owners::ModelOwnerVehicle},
              friends: ::V1::Schemas::Models::Owners::ModelOwnerFriends,
              fleets: {type: :array, items: ::V1::Schemas::Models::Owners::ModelOwnerFleet}
            },
            additionalProperties: false,
            required: %w[vehicles friends fleets]
          })
        end
      end
    end
  end
end

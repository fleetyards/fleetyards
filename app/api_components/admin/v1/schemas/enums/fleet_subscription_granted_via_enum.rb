# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class FleetSubscriptionGrantedViaEnum
          include OpenapiRuby::Components::Base

          GRANTS = ::FleetSubscription::GRANTS

          schema({
            type: :string,
            enum: GRANTS,
            "x-enumNames": GRANTS.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end

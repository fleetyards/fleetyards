# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Dashboard
        class FleetHealthMembers
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              count: {type: :integer},
              sample: {
                type: :array,
                items: ::V1::Schemas::Fleets::Dashboard::FleetHealthMember
              }
            },
            required: %w[count sample]
          })
        end
      end
    end
  end
end

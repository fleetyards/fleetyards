# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetResourceAccessGroupsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Fleets::FleetResourceAccessGroup
        })
      end
    end
  end
end

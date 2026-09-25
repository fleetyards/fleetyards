# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractDestinationsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Contracts::FleetContractDestination
        })
      end
    end
  end
end

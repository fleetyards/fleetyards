# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractCrewList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Contracts::FleetContractCrewMember
        })
      end
    end
  end
end

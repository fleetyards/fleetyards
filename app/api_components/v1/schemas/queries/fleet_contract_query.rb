# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetContractQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            titleCont: {type: :string},
            stateEq: ::V1::Schemas::Enums::FleetContractStateEnum,
            stateIn: {
              type: :array,
              items: ::V1::Schemas::Enums::FleetContractStateEnum
            },
            kindEq: ::V1::Schemas::Enums::FleetContractKindEnum,
            s: ::V1::Schemas::Sorts::FleetContractSortEnum
          },
          additionalProperties: false
        })
      end
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # Create and update share one shape. Everything but the title is optional
      # on both, because a contract is written over several saves before it is
      # published -- and `FleetContract#ready_to_publish?` is what refuses an
      # incomplete one, at the point where it would become an offer of work.
      class FleetContractInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: [:string, :null]},
            description: {type: [:string, :null]},
            kind: ::V1::Schemas::Enums::FleetContractKindEnum,
            reward: {type: :string},
            reimburseExpenses: {type: :boolean},
            crewLimit: {type: [:integer, :null]},
            deadline: {type: [:string, :null], format: "date-time"},
            # Only a transport contract may carry a source, and it must carry
            # one. The model refuses the other three combinations.
            sourceFleetInventoryId: {type: [:string, :null], format: :uuid},
            destinationFleetInventoryId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: []
        })
      end
    end
  end
end

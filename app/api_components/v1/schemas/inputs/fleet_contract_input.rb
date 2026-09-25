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
            # The picture, the way a fleet event carries one: either art the
            # author uploaded or the key of a preset the app ships.
            coverImage: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]},
            # Only a transport contract may carry a source, and it must carry
            # one. The model refuses the other three combinations.
            sourceFleetInventoryId: {type: [:string, :null], format: :uuid},
            # Exactly one destination: a fleet inventory the author may write
            # to, or one of the author's own. Sending one clears the other.
            destinationFleetInventoryId: {type: [:string, :null], format: :uuid},
            destinationInventoryId: {type: [:string, :null], format: :uuid},
            # Who the work is for. `squadronOnly` with the squadrons it names
            # keeps the board to them; see SquadronRestrictable.
            visibility: ::V1::Schemas::Enums::FleetContractVisibilityEnum,
            fleetSquadronIds: {type: :array, items: {type: :string, format: :uuid}},
            # The goods, when a contract arrives with them. Saved with it in one
            # transaction, because a contract with nothing to deliver cannot be
            # published and a second form to add them is the long way round.
            items: {type: :array, items: ::V1::Schemas::Inputs::FleetContractItemInput}
          },
          additionalProperties: false,
          required: []
        })
      end
    end
  end
end

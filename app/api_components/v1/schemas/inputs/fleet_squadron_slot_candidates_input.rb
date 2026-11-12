# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronSlotCandidatesInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            candidates: {type: :array, items: ::V1::Schemas::Inputs::FleetSquadronSlotCandidateInput}
          },
          additionalProperties: false,
          required: %w[candidates]
        })
      end
    end
  end
end

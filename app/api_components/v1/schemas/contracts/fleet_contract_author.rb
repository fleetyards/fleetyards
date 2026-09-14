# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # Who posted the contract. Null once that account was deleted -- the
      # foreign key is ON DELETE SET NULL, so a fleet's contract history
      # survives the person who wrote it.
      class FleetContractAuthor
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string}
          },
          additionalProperties: false,
          required: %w[id username]
        })
      end
    end
  end
end

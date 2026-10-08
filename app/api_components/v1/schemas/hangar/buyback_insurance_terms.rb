# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BuybackInsuranceTerms
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            months: {type: :array, items: {type: :integer}, description: "Month terms, longest first; lifetime pledges excluded"},
            lifetime: {type: :boolean, description: "Whether any pledge has lifetime insurance"},
            none: {type: :boolean, description: "Whether any pledge has no insurance"}
          },
          additionalProperties: false,
          required: %w[months lifetime none]
        })
      end
    end
  end
end

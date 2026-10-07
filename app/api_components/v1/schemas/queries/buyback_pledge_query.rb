# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class BuybackPledgeQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kindEq: ::V1::Schemas::Enums::BuybackPledgeKindEnum,
            nameCont: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end

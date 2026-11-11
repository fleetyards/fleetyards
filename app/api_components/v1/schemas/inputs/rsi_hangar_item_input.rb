# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiHangarItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string},
            name: {type: :string},
            customName: {type: :string},
            type: ::V1::Schemas::Enums::RsiHangarItemKindEnum,
            image: {type: :string, format: :uri},
            pledgeName: {type: :string},
            pledgeValue: {type: :number, description: "What melting the whole pledge returns, in USD"},
            pledgeItemCount: {type: :integer, description: "How many items the pledge holds, of any kind"},
            pledgeCreatedOn: {type: :string, format: :date},
            meltable: {type: :boolean, description: "Whether RSI offers to melt the pledge"},
            lifetimeInsurance: {type: :boolean, description: "Whether the pledge comes with lifetime insurance"},
            insuranceMonths: {type: :integer, minimum: 0, description: "How many months of insurance the pledge comes with, when not lifetime"},
            page: {type: :integer, description: "The page of the RSI hangar the pledge was read from"}
          },
          additionalProperties: false,
          required: %w[id name type]
        })
      end
    end
  end
end

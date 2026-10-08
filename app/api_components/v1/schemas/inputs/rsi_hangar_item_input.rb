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
            meltable: {type: :boolean, description: "Whether RSI offers to melt the pledge"}
          },
          additionalProperties: false,
          required: %w[id name type]
        })
      end
    end
  end
end

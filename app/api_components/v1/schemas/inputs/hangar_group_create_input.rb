# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarGroupCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            color: {type: :string},
            sort: {type: [:integer, :null]},
            public: {type: [:boolean, :null]}
          },
          additionalProperties: false,
          required: %w[name color]
        })
      end
    end
  end
end

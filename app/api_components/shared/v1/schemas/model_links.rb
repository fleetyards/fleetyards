# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelLinks
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            salesPageUrl: {type: :string},
            storeUrl: {type: :string}
          },
          additionalProperties: false

        })
      end
    end
  end
end

# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BaseList
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            meta: ::Shared::V1::Schemas::Meta
          },
          additionalProperties: false,
          required: %w[meta]
        })
      end
    end
  end
end

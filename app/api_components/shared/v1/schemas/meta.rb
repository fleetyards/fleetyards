# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Meta
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            pagination: ::Shared::V1::Schemas::Pagination
          },
          additionalProperties: false
        })
      end
    end
  end
end

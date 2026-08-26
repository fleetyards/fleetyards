# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      # The slugs a fleetchart wants views for. Named like the filter the caller
      # just used on the list it is augmenting.
      class FleetchartViewQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slugIn: {type: :array, items: {type: :string}}
          }
        })
      end
    end
  end
end

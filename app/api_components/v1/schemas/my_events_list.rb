# frozen_string_literal: true

module V1
  module Schemas
    class MyEventsList
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          items: {type: :array, items: ::V1::Schemas::MyEvent}
        },
        additionalProperties: false,
        required: %w[items]
      })
    end
  end
end

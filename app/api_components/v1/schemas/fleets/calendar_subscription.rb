# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class CalendarSubscription
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            enabled: {type: :boolean},
            feedUrl: {type: :string, format: :uri, nullable: true}
          },
          required: %w[enabled feedUrl],
          additionalProperties: false
        })
      end
    end
  end
end

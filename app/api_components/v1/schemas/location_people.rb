# frozen_string_literal: true

module V1
  module Schemas
    # The reader's friends and fleet mates whose current location is a place
    # or somewhere inside it.
    class LocationPeople
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # How many there are in all; `people` holds the first `limit`.
          totalCount: {type: :integer},
          people: {type: :array, items: ::V1::Schemas::LocationPerson}
        },
        additionalProperties: false,
        required: %w[totalCount people]
      })
    end
  end
end

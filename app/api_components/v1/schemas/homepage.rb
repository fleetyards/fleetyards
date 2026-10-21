# frozen_string_literal: true

module V1
  module Schemas
    # What the landing page offers: a ship, a place and an item to search for,
    # and one of the ships the team features. Both are picked anew each visit;
    # `featuredShip` is absent while none can be shown.
    class Homepage
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          searchSuggestions: {type: :array, items: {type: :string}},
          featuredShip: ::V1::Schemas::HomepageFeaturedShip
        },
        additionalProperties: false,
        required: %w[searchSuggestions]
      })
    end
  end
end

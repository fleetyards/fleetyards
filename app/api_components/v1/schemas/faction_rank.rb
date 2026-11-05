# frozen_string_literal: true

module V1
  module Schemas
    # One rank on a ladder, and the points it starts at. Negative on the ranks a
    # player falls to.
    class FactionRank
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          minReputation: {type: :integer}
        },
        additionalProperties: false,
        required: %w[name minReputation]
      })
    end
  end
end

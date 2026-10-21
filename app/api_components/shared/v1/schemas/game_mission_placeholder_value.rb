# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What the files state for one `~mission(Token)` placeholder. A list
      # rather than a map keyed by token, because response keys are camelised
      # and a token is matched as the text writes it.
      class GameMissionPlaceholderValue
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            token: {type: :string},
            # Can carry a placeholder of its own and the game's `<EM4>` markup.
            value: {type: :string}
          },
          additionalProperties: false,
          required: %w[token value]
        })
      end
    end
  end
end

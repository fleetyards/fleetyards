# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Same two fields as UserRef, but both required. Kept apart so neither
      # published contract changes.
      class UserRefRequired
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string}
          },
          required: %w[id username]
        })
      end
    end
  end
end

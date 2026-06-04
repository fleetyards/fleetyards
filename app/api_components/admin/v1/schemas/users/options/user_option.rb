# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Users
        module Options
          class UserOption
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                username: {type: :string}
              },
              additionalProperties: false,
              required: %w[id username]
            })
          end
        end
      end
    end
  end
end

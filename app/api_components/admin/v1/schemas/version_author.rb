# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class VersionAuthor
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

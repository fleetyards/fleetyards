# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class VersionChange
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            field: {type: :string},
            from: {type: :string, nullable: true},
            to: {type: :string, nullable: true}
          },
          required: %w[field]
        })
      end
    end
  end
end

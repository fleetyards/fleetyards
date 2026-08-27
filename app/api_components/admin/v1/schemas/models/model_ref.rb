# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        # A model by id, name and slug.
        class ModelRef
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string}
            },
            required: %w[id name slug]
          })
        end
      end
    end
  end
end

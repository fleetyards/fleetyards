# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class HomepageSetting
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            featuredModelIds: {type: :array, items: {type: :string, format: :uuid}},
            featuredRandom: {type: :boolean},
            featuredHidden: {type: :boolean},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[featuredModelIds featuredRandom featuredHidden]
        })
      end
    end
  end
end

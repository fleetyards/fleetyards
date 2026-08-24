# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Manufacturer < ::V1::Schemas::Manufacturer
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            id: {type: :string, format: "uuid"},
            iconOverridden: {type: :boolean}
          },
          required: %w[id iconOverridden]
        })
      end
    end
  end
end

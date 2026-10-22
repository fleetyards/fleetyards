# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Manufacturer < ::V1::Schemas::Manufacturer
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            id: {type: :string, format: "uuid"},
            iconOverridden: {type: :boolean},
            logoOverridden: {type: :boolean},
            shipyardLocation: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]}
          },
          required: %w[id iconOverridden logoOverridden]
        })
      end
    end
  end
end

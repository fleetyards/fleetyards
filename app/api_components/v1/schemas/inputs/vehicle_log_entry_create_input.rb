# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLogEntryCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            body: {type: [:string, :null]},
            loggedAt: {type: [:string, :null], format: "date-time"},
            public: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[title]
        })
      end
    end
  end
end

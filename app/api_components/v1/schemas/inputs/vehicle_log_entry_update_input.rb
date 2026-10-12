# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLogEntryUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            body: {type: [:string, :null]},
            loggedAt: {type: :string, format: "date-time"},
            public: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end

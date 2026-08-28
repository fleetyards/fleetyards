# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class NotificationBulkInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            ids: {type: :array, items: {type: :string, format: :uuid}},
            all: {
              type: :boolean,
              default: false,
              description: "Apply to every notification matching `q` instead of `ids`."
            },
            q: ::V1::Schemas::Queries::NotificationQuery
          },
          additionalProperties: false,
          description: "Naming neither `ids` nor `all` selects nothing."
        })
      end
    end
  end
end

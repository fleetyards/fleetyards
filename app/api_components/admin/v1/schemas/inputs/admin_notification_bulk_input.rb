# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class AdminNotificationBulkInput
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
              q: ::Admin::V1::Schemas::Queries::AdminNotificationQuery
            },
            additionalProperties: false,
            description: "Naming neither `ids` nor `all` selects nothing."
          })
        end
      end
    end
  end
end

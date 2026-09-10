# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class OauthApplicationRejectBulkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              rejectionReason: {type: :string},
              ids: {type: :array, items: {type: :string, format: :uuid}},
              all: {
                type: :boolean,
                default: false,
                description: "Apply to every application matching `q` instead of `ids`."
              },
              q: ::Admin::V1::Schemas::Queries::OauthApplicationQuery
            },
            additionalProperties: false,
            required: %w[rejectionReason],
            description: "Naming neither `ids` nor `all` selects nothing."
          })
        end
      end
    end
  end
end

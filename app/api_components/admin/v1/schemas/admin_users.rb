# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminUsers < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/AdminUser"}}
          },
          required: %w[items]
        })
      end
    end
  end
end

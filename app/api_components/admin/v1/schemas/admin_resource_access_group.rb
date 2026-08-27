# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminResourceAccessGroup
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            key: {type: :string},
            privileges: {type: :array, items: ::Admin::V1::Schemas::Enums::AdminUserResourceAccessEnum}
          },
          additionalProperties: false,
          required: %w[key privileges]
        })
      end
    end
  end
end

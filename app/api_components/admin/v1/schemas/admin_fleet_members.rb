# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminFleetMembers < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/AdminFleetMember"}}
          },
          required: %w[items]
        })
      end
    end
  end
end

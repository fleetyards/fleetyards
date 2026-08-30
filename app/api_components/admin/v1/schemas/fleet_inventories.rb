# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FleetInventories < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: ::Admin::V1::Schemas::FleetInventory}
          },
          required: %w[items]
        })
      end
    end
  end
end

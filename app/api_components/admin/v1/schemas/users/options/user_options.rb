# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Users
        module Options
          class UserOptions < Shared::V1::Schemas::BaseList
            include OpenapiRuby::Components::Base

            schema({
              properties: {
                items: {type: :array, items: {"$ref": "#/components/schemas/UserOption"}}
              },
              required: %w[items]
            })
          end
        end
      end
    end
  end
end

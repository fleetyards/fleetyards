# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminResourceAccessGroupsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/AdminResourceAccessGroup"}
        })
      end
    end
  end
end

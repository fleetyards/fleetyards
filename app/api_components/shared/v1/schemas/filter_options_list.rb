# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class FilterOptionsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/FilterOption"}
        })
      end
    end
  end
end

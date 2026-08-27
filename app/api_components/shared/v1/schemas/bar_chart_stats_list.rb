# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BarChartStatsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/BarChartStats"}
        })
      end
    end
  end
end

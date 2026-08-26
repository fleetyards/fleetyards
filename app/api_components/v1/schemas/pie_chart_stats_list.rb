# frozen_string_literal: true

module V1
  module Schemas
    class PieChartStatsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/PieChartStats"}
      })
    end
  end
end

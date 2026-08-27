# frozen_string_literal: true

module V1
  module Schemas
    class PieChartStatsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::PieChartStats
      })
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarStatsPublic
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            wishlistTotal: {type: :integer},
            classifications: {type: :array, items: ::V1::Schemas::Hangar::HangarClassificationMetric},
            groups: {type: :array, items: ::V1::Schemas::Hangar::Groups::HangarGroupMetric},
            metrics: ::V1::Schemas::Hangar::HangarMetricsPublic
          },
          additionalProperties: false,
          required: %w[total classifications groups metrics]
        })
      end
    end
  end
end

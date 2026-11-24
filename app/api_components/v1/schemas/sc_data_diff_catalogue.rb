# frozen_string_literal: true

module V1
  module Schemas
    # `recorded` is false when one of the builds has no rows for the catalogue
    # at all, which is not the same as everything being new.
    class ScDataDiffCatalogue
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          catalogue: ::V1::Schemas::Enums::ScDataDiffCatalogueEnum,
          recorded: {type: :boolean},
          counts: ::V1::Schemas::ScDataDiffCounts
        },
        additionalProperties: false,
        required: %w[catalogue recorded counts]
      })
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BlueprintLogImportResult
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            imported: {type: :integer, description: "Newly marked as owned, including those taken off the wishlist"},
            unchanged: {type: :integer, description: "Already owned before the import"},
            importId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[imported unchanged importId]
        })
      end
    end
  end
end

# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class SearchResultTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: %w[Model Component Shop Station CelestialObject Starsystem Equipment Commodity]
          })
        end
      end
    end
  end
end

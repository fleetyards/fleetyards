# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetDirectoryQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Name, FID or RSI SID, matched anywhere.
            search: {type: :string},
            memberCountGteq: {type: :integer},
            memberCountLteq: {type: :integer},
            alignmentIn: {type: :array, items: ::V1::Schemas::Enums::FleetAlignmentEnum},
            # Either the primary or the secondary activity.
            activityIn: {type: :array, items: ::V1::Schemas::Enums::FleetActivityEnum},
            languageIn: {type: :array, items: ::V1::Schemas::Enums::FleetLanguageEnum},
            commitmentIn: {type: :array, items: ::V1::Schemas::Enums::FleetCommitmentEnum},
            roleplayEq: {type: :boolean},
            recruitingEq: {type: :boolean},
            defaultTimezoneIn: {type: :array, items: {type: :string}},
            s: ::V1::Schemas::Enums::FleetDirectorySortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::FleetDirectorySortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end

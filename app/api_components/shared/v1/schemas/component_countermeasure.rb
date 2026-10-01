# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentCountermeasure
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kind: ::Shared::V1::Schemas::Enums::ComponentCountermeasureKindEnum,
            # Seconds a decoy burns, or a noise cloud lasts once it spawns.
            lifetime: {type: :number},
            # Seconds before a noise cloud spawns; absent on a decoy.
            spawnDelay: {type: :number},
            infrared: ComponentSignatureRange,
            electromagnetic: ComponentSignatureRange,
            crossSection: ComponentSignatureRange
          },
          additionalProperties: false
        })
      end
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Groups
        class PublicHangarGroupsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/HangarGroupPublic"}
          })
        end
      end
    end
  end
end

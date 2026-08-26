# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Groups
        class HangarGroupsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/HangarGroup"}
          })
        end
      end
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarPaintsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {type: :string, format: :uuid}
        })
      end
    end
  end
end

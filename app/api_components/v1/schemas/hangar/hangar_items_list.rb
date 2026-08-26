# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarItemsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {type: :string}
        })
      end
    end
  end
end

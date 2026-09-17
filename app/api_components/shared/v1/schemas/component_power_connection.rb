# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The older power figures. Three components still carry them; for
      # everything else the live numbers moved into `typeData.powerRanges`.
      class ComponentPowerConnection
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            powerBase: {type: :number},
            powerDraw: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end

# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTemperature
        include OpenapiRuby::Components::Base

        # In kelvin. The overheat and misfire figures are there only for an
        # item that can overheat, the IR ones only for an item whose IR
        # signature follows its temperature.
        schema({
          type: :object,
          properties: {
            minCoolingTemperature: {type: :number},
            overheatTemperature: {type: :number},
            overheatWarningTemperature: {type: :number},
            overheatRecoveryTemperature: {type: :number},
            misfireMinTemperature: {type: :number},
            misfireMaxTemperature: {type: :number},
            irStartTemperature: {type: :number},
            irPerKelvin: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetCheckInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fid: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end

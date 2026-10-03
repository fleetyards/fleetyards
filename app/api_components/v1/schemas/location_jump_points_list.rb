# frozen_string_literal: true

module V1
  module Schemas
    class LocationJumpPointsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::LocationJumpPoint
      })
    end
  end
end

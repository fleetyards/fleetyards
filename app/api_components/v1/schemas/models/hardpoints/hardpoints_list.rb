# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Hardpoints
        class HardpointsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::Shared::V1::Schemas::Hardpoint
          })
        end
      end
    end
  end
end

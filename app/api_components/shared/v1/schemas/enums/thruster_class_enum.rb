# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ThrusterClassEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: %w[main retro vtol mav]
          })
        end
      end
    end
  end
end

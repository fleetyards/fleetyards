# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class HardpointGroupEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Hardpoint.groups.keys
          })
        end
      end
    end
  end
end

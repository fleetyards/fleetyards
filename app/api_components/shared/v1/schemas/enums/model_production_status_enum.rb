# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelProductionStatusEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Model::PRODUCTION_STATUSES
          })
        end
      end
    end
  end
end

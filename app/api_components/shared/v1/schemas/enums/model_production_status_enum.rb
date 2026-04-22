# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelProductionStatusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Model::PRODUCTION_STATUSES,
            "x-enumNames": ::Model::PRODUCTION_STATUSES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end

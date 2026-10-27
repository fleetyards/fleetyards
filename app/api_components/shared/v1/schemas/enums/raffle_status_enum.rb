# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class RaffleStatusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Raffle::STATUSES,
            "x-enumNames": ::Raffle::STATUSES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end

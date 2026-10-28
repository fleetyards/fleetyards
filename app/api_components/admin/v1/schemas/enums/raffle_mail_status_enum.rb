# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class RaffleMailStatusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::RaffleEntry::MAIL_STATUSES,
            "x-enumNames": ::RaffleEntry::MAIL_STATUSES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end

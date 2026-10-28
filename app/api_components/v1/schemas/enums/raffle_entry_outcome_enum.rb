# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class RaffleEntryOutcomeEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::RaffleEntry::OUTCOMES,
          "x-enumNames": ::RaffleEntry::OUTCOMES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end

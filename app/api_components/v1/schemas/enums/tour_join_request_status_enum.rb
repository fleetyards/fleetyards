# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class TourJoinRequestStatusEnum
        include OpenapiRuby::Components::Base

        # Sourced from the model rather than re-typed: a schema-local copy
        # drifts the moment a state is added, and the API contract would keep
        # describing a set the record no longer has.
        VALUES = ::TourJoinRequest.aasm.states.map { |state| state.name.to_s }.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end

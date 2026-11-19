# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FeedbackStateEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::Feedback.aasm.states.map { |state| state.name.to_s },
          "x-enumNames": ::Feedback.aasm.states.map { |state| transform_enum_key(state.name.to_s) }
        })
      end
    end
  end
end

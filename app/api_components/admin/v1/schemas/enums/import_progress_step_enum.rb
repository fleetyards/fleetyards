# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class ImportProgressStepEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Imports::Progress::STEPS,
            "x-enumNames": ::Imports::Progress::STEPS.map { |step| transform_enum_key(step) }
          })
        end
      end
    end
  end
end

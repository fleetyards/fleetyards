# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ImportProgress
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            step: ::Admin::V1::Schemas::Enums::ImportProgressStepEnum,
            stepNumber: {type: :integer},
            steps: {type: :integer},
            done: {type: :integer},
            # Absent while the step has nothing to count.
            total: {type: :integer},
            progressedAt: {type: :string, format: "date-time"}
          },
          required: %w[step stepNumber steps done progressedAt]
        })
      end
    end
  end
end

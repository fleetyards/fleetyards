# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelLoanerInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid},
              loanerModelId: {type: :string, format: :uuid},
              hidden: {type: :boolean, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end

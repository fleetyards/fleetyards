# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class UnlistedModelDecisionEnum
          include OpenapiRuby::Components::Base

          schema({
            type: [:string, :null],
            enum: ::ScDataUnlistedModel::DECISIONS + [nil]
          })
        end
      end
    end
  end
end

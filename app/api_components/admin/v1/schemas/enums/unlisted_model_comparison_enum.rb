# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class UnlistedModelComparisonEnum
          include OpenapiRuby::Components::Base

          schema({
            type: [:string, :null],
            enum: ::ScDataUnlistedModel::COMPARISONS + [nil]
          })
        end
      end
    end
  end
end

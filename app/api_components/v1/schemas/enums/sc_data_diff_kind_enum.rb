# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ScDataDiffKindEnum
        include OpenapiRuby::Components::Base

        schema({type: :string, enum: ::ScData::BuildDiff::KINDS})
      end
    end
  end
end

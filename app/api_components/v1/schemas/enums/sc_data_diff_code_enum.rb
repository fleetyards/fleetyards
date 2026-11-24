# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Whether the two builds were read by the same parsers and loaders.
      class ScDataDiffCodeEnum
        include OpenapiRuby::Components::Base

        schema({type: :string, enum: ::ScData::CodeDigest::RELATIONS})
      end
    end
  end
end

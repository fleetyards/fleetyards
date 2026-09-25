# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Its own component rather than anyOf: [$ref, {type: :null}], which oasdiff
      # reads as every required property removed.
      class NullableCommodityRef < CommodityRef
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null]
        })
      end
    end
  end
end

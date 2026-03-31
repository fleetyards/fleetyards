# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Image < ::V1::Schemas::Image
        include Rswag::SchemaComponents::Component

        schema({
          properties: {
            size: {type: :number},
            enabled: {type: :boolean},
            global: {type: :boolean}
          },
          required: %w[enabled global]
        })
      end
    end
  end
end

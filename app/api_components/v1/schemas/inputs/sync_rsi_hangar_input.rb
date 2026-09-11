# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SyncRsiHangarInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: ::V1::Schemas::Inputs::RsiHangarItemInput
            },
            hangarGroupId: {type: :string, format: :uuid}
          }
        })
      end
    end
  end
end

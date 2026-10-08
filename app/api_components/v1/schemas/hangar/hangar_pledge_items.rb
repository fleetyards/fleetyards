# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarPledgeItems < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: ::V1::Schemas::Hangar::HangarPledgeItem}
          },
          required: %w[items]
        })
      end
    end
  end
end

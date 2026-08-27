# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Upgrades
          class AdminModelUpgradeMedia
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                storeImage: ::Shared::V1::Schemas::MediaFile
              },
              additionalProperties: false
            })
          end
        end
      end
    end
  end
end

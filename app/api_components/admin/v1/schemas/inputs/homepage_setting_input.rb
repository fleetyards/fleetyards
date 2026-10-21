# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class HomepageSettingInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              featuredModelIds: {type: :array, items: {type: :string, format: :uuid}, maxItems: ::HomepageSetting::MAX_FEATURED_MODELS},
              featuredRandom: {type: :boolean}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end

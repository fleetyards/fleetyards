# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class NotificationPreferenceUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            app: {type: :boolean},
            mail: {type: :boolean},
            push: {type: :boolean},
            discord: {type: :boolean}
          }
        })
      end
    end
  end
end

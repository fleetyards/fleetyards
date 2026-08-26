# frozen_string_literal: true

module V1
  module Schemas
    class NotificationPreferencesList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/NotificationPreference"}
      })
    end
  end
end

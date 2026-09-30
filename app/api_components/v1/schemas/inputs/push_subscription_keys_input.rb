# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PushSubscriptionKeysInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            p256dh: {type: :string},
            auth: {type: :string}
          },
          required: %w[p256dh auth]
        })
      end
    end
  end
end

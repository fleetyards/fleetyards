# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # The shape of the browser's own `PushSubscription#toJSON()`, so the
      # client can post it as it comes.
      class PushSubscriptionInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            endpoint: {type: :string},
            expirationTime: {type: [:number, :null]},
            keys: ::V1::Schemas::Inputs::PushSubscriptionKeysInput
          },
          required: %w[endpoint keys]
        })
      end
    end
  end
end

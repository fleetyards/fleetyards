# frozen_string_literal: true

module V1
  module Schemas
    class PushSubscriptionsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::PushSubscription
      })
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    class MyRaffleEntries < ::Shared::V1::Schemas::BaseList
      include OpenapiRuby::Components::Base

      schema({
        properties: {
          items: {type: :array, items: ::V1::Schemas::MyRaffleEntry}
        },
        required: %w[items]
      })
    end
  end
end

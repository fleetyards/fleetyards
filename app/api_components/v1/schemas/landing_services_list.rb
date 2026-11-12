# frozen_string_literal: true

module V1
  module Schemas
    class LandingServicesList
      include OpenapiRuby::Components::Base

      schema({type: :array, items: ::V1::Schemas::LandingService})
    end
  end
end

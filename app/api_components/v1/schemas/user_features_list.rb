# frozen_string_literal: true

module V1
  module Schemas
    class UserFeaturesList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::UserFeature
      })
    end
  end
end

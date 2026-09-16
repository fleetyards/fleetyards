# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FeatureChangesList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::Admin::V1::Schemas::FeatureChange
        })
      end
    end
  end
end

# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class FleetchartViewsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Models::FleetchartView
        })
      end
    end
  end
end

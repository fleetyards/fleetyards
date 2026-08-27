# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class FilterOptionsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::Shared::V1::Schemas::FilterOption
        })
      end
    end
  end
end

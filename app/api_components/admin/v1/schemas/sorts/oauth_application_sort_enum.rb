# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Sorts
        class OauthApplicationSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Oauth::Application::ADMIN_SORTING_PARAMS,
            "x-enumNames": ::Oauth::Application::ADMIN_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end

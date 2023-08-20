# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ShopsController < ::Api::PublicBaseController
        def types
          @filters = Shop.type_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V2
    module Filters
      class ModelsController < ::Api::V2::BaseController
        before_action :authenticate_user!, only: []

        def slugs
          authorize! :index, :api_models
          render json: Model.order(slug: :asc).all.pluck(:slug)
        end

        def production_states
          authorize! :index, :api_models
          @production_states = Model.production_status_filters
        end

        def classifications
          authorize! :index, :api_models
          @classifications = Model.classification_filters
        end

        def focus
          authorize! :index, :api_models
          @focus = Model.focus_filters
        end

        def sizes
          authorize! :index, :api_models
          @sizes = Model.size_filters
        end

        def filters
          authorize! :index, :api_models
          @filters ||= begin
            filters = []
            filters << Manufacturer.model_filters
            filters << Model.production_status_filters
            filters << Model.classification_filters
            filters << Model.focus_filters
            filters << Model.size_filters
            filters.flatten
              .sort_by { |filter| [filter.category, filter.name] }
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class SearchController < ::Api::BaseController
      before_action :authenticate_user!, only: %i[]
      after_action -> { pagination_header(:results) }, only: [:index]

      skip_verify_authorized

      def index
        @results = Searchkick.search(
          search_query_params[:search],
          models: [Model, Component, Equipment],
          fields: [
            {"name^5": :word_start}, {manufacturer_name: :word_start}, {item_type: :word_start},
            {equipment_type: :word_start},
            "manufacturer_code", "item_class", "slot"
          ],
          indices_boost: {
            Model => 10,
            Component => 4,
            Equipment => 4
          },
          misspellings: {below: 5},
          page: params[:page],
          per_page: 30
        )
      end

      private def search_query_params
        @search_query_params ||= params.transform_keys(&:underscore)
          .permit(:search)
      end
    end
  end
end

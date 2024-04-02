# frozen_string_literal: true

module Api
  module V1
    class SearchController < ::Api::BaseController
      before_action :authenticate_user!, only: %i[]
      after_action -> { pagination_header(:results) }, only: [:index]

      def index
        authorize! :index, :api_search

        @results = Model.search(
          search_query_params[:search],
          fields: [
            {"name^5": :word_start}, {manufacturer_name: :word_start}, "manufacturer_code"
          ],
          misspellings: {below: 5},
          page: params[:page],
          per_page: 30
        )
      end

      private def search_query_params
        @search_query_params ||= query_params(:search)
      end
    end
  end
end

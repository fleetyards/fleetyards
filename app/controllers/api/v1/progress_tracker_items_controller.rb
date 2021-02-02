# frozen_string_literal: true

module Api
  module V1
    class ProgressTrackerItemsController < ::Api::BaseController
      before_action :authenticate_user!, only: %i[]
      after_action -> { pagination_header(:items) }, only: %i[index]

      def index
        authorize! :index, :api_roadmap

        @items = ProgressTrackerItem.search(
          search_params,
          fields: [{ title: :word_start }],
          where: query_params,
          order: order_params,
          page: params[:page],
          per_page: per_page(ProgressTrackerItem)
        )
      end

      private def search_params
        @search_params ||= params.permit(:search)[:search] || '*'
      end

      private def order_params
        @order_params ||= begin
          permitted_params = params.permit(
            order: [
              :title
            ]
          )

          permitted_params[:order] || { 'title' => 'asc', 'start_date' => 'asc' }
        end
      end

      private def query_params
        @query_params ||= begin
          permitted_params = params.permit(
            query: [
              :in_progress, :planned, :done, :with_model, { team: [], model_id: [] }
            ]
          )

          permitted_params[:query] || {}
        end
      end
    end
  end
end

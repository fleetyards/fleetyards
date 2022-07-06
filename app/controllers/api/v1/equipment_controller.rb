# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:equipment) }, only: [:index]

      def index
        authorize! :index, :api_equipment

        @equipment = Equipment.search(
          search_params || '*',
          fields: [{ name: :word_start }],
          where: query_params,
          order: order_params,
          page: params[:page],
          per_page: per_page(Equipment),
          includes: %i[manufacturer]
        )
      end

      def show
        authorize! :show, :api_equipment
        @equipment = Equipment.find_by!(slug: params[:slug])
      end

      private def search_params
        @search_params ||= params.permit(:search)[:search]
      end

      private def order_params
        @order_params ||= begin
          permitted_params = params.permit(
            order: [
              :name
            ]
          )

          permitted_params[:order] || { 'name' => 'asc' }
        end
      end

      private def query_params
        @query_params ||= begin
          permitted_params = params.permit(
            query: [{
              name: [], id: [], item_type: [], equipment_type: [], manufacturer_code: [],
              manufacturer_name: [], slot: [],
            }]
          )

          permitted_params[:query] || {}
        end
      end
    end
  end
end

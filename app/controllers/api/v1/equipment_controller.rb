# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_equipment

        equipment_query_params['sorts'] = sort_by_name

        @q = Equipment.ransack(equipment_query_params)

        @equipment = @q.result.offset(params[:offset]).limit(params[:limit])
      end

      private def equipment_query_params
        @equipment_query_params ||= query_params
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V2
    class EquipmentController < ::Api::V2::BaseController
      before_action :authenticate_user!, only: []

      def index
        authorize! :index, :api_equipment

        equipment_query_params["sorts"] = sort_by_name

        @q = Equipment.includes(:manufacturer).ransack(equipment_query_params)

        @equipment = @q.result
          .page(params[:page])
          .per(per_page(Equipment))
      end

      private def equipment_query_params
        @equipment_query_params ||= query_params(:name_cont, id_in: [], name_in: [])
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:equipment) }, only: [:index]

      def index
        authorize! :index, :api_equipment

        equipment_query_params['sorts'] = sort_by_name

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

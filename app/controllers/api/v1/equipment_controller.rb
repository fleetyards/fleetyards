# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::PublicBaseController
      after_action -> { pagination_header(:equipment) }, only: [:index]

      def index
        equipment_query_params["sorts"] = "name asc"

        @q = Equipment.includes(:manufacturer).ransack(equipment_query_params)

        @equipment = @q.result
          .page(params[:page])
          .per(per_page(Equipment))
      end

      private def equipment_query_params
        @equipment_query_params ||= parems.permit(q: [:name_cont, id_in: [], name_in: []]).fetch(:q, {})
      end
    end
  end
end

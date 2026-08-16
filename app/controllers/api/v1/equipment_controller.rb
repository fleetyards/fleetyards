# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      after_action -> { pagination_header(:equipment) }, only: [:index]

      def index
        equipment_query_params["sorts"] = "name asc"

        # Skins, NPC loadouts and event copies carry their own record but are
        # not something a player holds, so the list leaves them out.
        @q = Equipment.visible.includes(:manufacturer).ransack(equipment_query_params)

        @equipment = @q.result
          .page(params[:page])
          .per(per_page(Equipment))
      end

      private def equipment_query_params
        @equipment_query_params ||= params.permit(q: [
          :name_cont,
          id_in: [], name_in: [], slug_in: [], equipment_type_in: [], item_type_in: [],
          manufacturer_slug_in: []
        ]).fetch(:q, {})
      end
    end
  end
end

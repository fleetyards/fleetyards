# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      after_action -> { pagination_header(:equipment) }, only: [:index]

      def index
        # Skins, NPC loadouts and event copies carry their own record but are
        # not something a player holds, so the list leaves them out. So does
        # gear a later patch stopped shipping, unless currentVersion=false asks
        # for it -- the rows stay so old ledger entries still resolve.
        @q = Equipment.visible
          .current_version(current_version)
          .includes(:manufacturer)
          .ransack(equipment_query_params)

        # Ordered here rather than through ransack: `ransack_alias :name` points
        # name at name_or_slug so that a search matches either, which leaves
        # ransack unable to sort by it.
        @equipment = @q.result
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(Equipment))
      end

      # Taken out of the ransack params rather than left in them: it is a scope,
      # not a column, and ransack would try to match a `current_version` field.
      private def current_version
        equipment_query_params.delete(:current_version) { true }
      end

      private def equipment_query_params
        @equipment_query_params ||= params.permit(q: [
          :name_cont, :current_version,
          id_in: [], name_in: [], slug_in: [], equipment_type_in: [], item_type_in: [],
          manufacturer_slug_in: []
        ]).fetch(:q, {})
      end
    end
  end
end

# frozen_string_literal: true

module Admin
  module Api
    module V1
      class EquipmentController < ::Admin::Api::BaseController
        def index
          authorize! :index, :admin_api_equipment

          equipment_query_params['sorts'] = sort_by_name

          @q = Equipment.includes(:manufacturer).ransack(equipment_query_params)

          @equipment = @q.result
            .page(params[:page])
            .per(per_page(Equipment))
        end

        def weapons
          authorize! :index, :admin_api_equipment

          @equipment = Equipment.where(equipment_type: :weapon).all
        end

        def attachments
          authorize! :index, :admin_api_equipment

          @equipment = Equipment.where(equipment_type: :weapon_attachment).all
        end

        def utilities
          authorize! :index, :admin_api_equipment

          @equipment = Equipment.where(equipment_type: :medical).all
        end
        private def equipment_query_params
          @equipment_query_params ||= query_params(
            :name_in, :id_eq, :name_cont, :name_eq
          )
        end
      end
    end
  end
end

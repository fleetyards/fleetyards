# frozen_string_literal: true

module Admin
  module Api
    module V1
      class VehiclesController < ::Admin::Api::BaseController
        include HangarFiltersConcern

        def index
          authorize! with: ::Admin::VehiclePolicy

          @q = index_scope

          @vehicles = @q.result
            .page(params[:page])
            .per(per_page(Model))
        end

        private def index_scope
          vehicle_query_params["sorts"] ||= sorting_params(Vehicle)

          scope = authorized_scope(Vehicle.all).includes(:user, model: :manufacturer).where(hidden: false)

          scope = loaner_included?(scope)

          scope.ransack(vehicle_query_params)
        end

        private def vehicle_query_params
          @vehicle_query_params ||= params.permit(q: [
            :search_cont, :name_cont, :model_name_cont, :id_eq, :model_id_eq,
            :loaner_eq, :wanted_eq,
            name_in: [], id_in: [], id_not_in: [], model_slug_in: [], model_name_in: [],
            model_id_in: [], model_id_not_in: [], model_production_status_in: [],
            manufacturer_in: [], user_username_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end

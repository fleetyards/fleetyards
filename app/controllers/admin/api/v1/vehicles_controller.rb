# frozen_string_literal: true

module Admin
  module Api
    module V1
      class VehiclesController < ::Admin::Api::BaseController
        include HangarFiltersConcern

        before_action :set_vehicle, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::VehiclePolicy

          @q = index_scope

          @vehicles = @q.result
            .page(params[:page])
            .per(per_page(Model))
        end

        def show
        end

        def update
          return if @vehicle.update(vehicle_params)

          render json: ValidationError.new("vehicle.update", errors: @vehicle.errors), status: :bad_request
        end

        def destroy
          return if @vehicle.destroy

          render json: ValidationError.new("vehicle.destroy", errors: @vehicle.errors), status: :bad_request
        end

        private def set_vehicle
          @vehicle = Vehicle.find(params[:id])

          authorize! @vehicle, with: ::Admin::VehiclePolicy
        end

        private def vehicle_params
          @vehicle_params ||= params.permit(
            :name, :serial, :wanted, :flagship, :public,
            :name_visible, :sale_notify, :hidden, :loaner, :bought_via
          )
        end

        private def index_scope
          vehicle_query_params["sorts"] ||= sorting_params(Vehicle, vehicle_query_params["sorts"])

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

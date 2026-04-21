# frozen_string_literal: true

module Admin
  module Api
    module V1
      class CargoHoldsController < ::Admin::Api::BaseController
        before_action :set_cargo_hold, only: %i[show update]

        def index
          authorize! with: ::Admin::CargoHoldPolicy

          @q = authorized_scope(CargoHold.includes(:parent)).ransack(cargo_hold_query_params)

          @cargo_holds = @q.result
            .order(:name)
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def show
        end

        def update
          if @cargo_hold.update(cargo_hold_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("cargo_hold.update", errors: @cargo_hold.errors), status: :bad_request
          end
        end

        private def set_cargo_hold
          @cargo_hold = CargoHold.find(params[:id])

          authorize! @cargo_hold, with: ::Admin::CargoHoldPolicy
        end

        private def cargo_hold_params
          @cargo_hold_params ||= params.permit(
            :offset_x, :offset_y, :offset_z, :rotation
          )
        end

        private def cargo_hold_query_params
          @cargo_hold_query_params ||= params.permit(q: [
            :parent_type_eq, :parent_id_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end

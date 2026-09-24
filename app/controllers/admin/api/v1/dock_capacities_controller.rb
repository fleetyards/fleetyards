# frozen_string_literal: true

module Admin
  module Api
    module V1
      class DockCapacitiesController < ::Admin::Api::BaseController
        before_action :set_dock_capacity, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::DockPolicy

          @q = authorized_scope(DockCapacity.all, with: ::Admin::DockPolicy).ransack(dock_capacity_query_params)

          @dock_capacities = @q.result
            .page(page_params)
            .per(params.fetch(:per_page, nil))
        end

        def create
          @dock_capacity = DockCapacity.new(dock_capacity_params)

          authorize! @dock_capacity, with: ::Admin::DockPolicy

          if @dock_capacity.save
            render :show, status: :created
          else
            render json: ValidationError.new("dock_capacity.create", errors: @dock_capacity.errors),
              status: :bad_request
          end
        end

        def show
        end

        def update
          if @dock_capacity.update(dock_capacity_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("dock_capacity.update", errors: @dock_capacity.errors),
              status: :bad_request
          end
        end

        def destroy
          @dock_capacity.destroy

          head :no_content
        end

        private def set_dock_capacity
          @dock_capacity = DockCapacity.find(params[:id])

          authorize! @dock_capacity, with: ::Admin::DockPolicy
        end

        private def dock_capacity_params
          @dock_capacity_params ||= params.permit(:dock_id, :ladder, :size, :quantity, :display)
        end

        private def dock_capacity_query_params
          @dock_capacity_query_params ||= params.permit(q: [
            :dock_id_eq, :ladder_eq, :size_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end

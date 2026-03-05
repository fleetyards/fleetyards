# frozen_string_literal: true

module Admin
  module Api
    module V1
      class DocksController < ::Admin::Api::BaseController
        before_action :set_dock, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::DockPolicy

          dock_query_params["sorts"] = "name asc"

          @q = authorized_scope(Dock.all).ransack(dock_query_params)

          @docks = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @dock = Dock.new(dock_params)

          authorize! @dock, with: ::Admin::DockPolicy

          if @dock.save
            render :show, status: :created
          else
            render json: ValidationError.new("dock.create", errors: @dock.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @dock.update(dock_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("dock.update", errors: @dock.errors), status: :bad_request
          end
        end

        def destroy
          @dock.destroy

          head :no_content
        end

        private def set_dock
          @dock = Dock.find(params[:id])

          authorize! @dock, with: ::Admin::DockPolicy
        end

        private def dock_params
          @dock_params ||= params.permit(
            :name, :dock_type, :ship_size, :group,
            :length, :beam, :height, :min_ship_size, :max_ship_size, :model_id
          )
        end

        private def dock_query_params
          @dock_query_params ||= params.permit(q: [
            :model_id_eq, :dock_type_eq, :ship_size_eq, :name_cont, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end

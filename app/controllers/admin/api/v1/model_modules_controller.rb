# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelModulesController < ::Admin::Api::BaseController
        before_action :set_model_module, only: %i[show update destroy link unlink]

        def index
          authorize! with: ::Admin::ModelModulePolicy

          model_module_query_params["sorts"] = "name asc"

          @q = authorized_scope(ModelModule.all).ransack(model_module_query_params)

          @model_modules = @q.result
            .includes(:module_hardpoints, :models, :manufacturer)
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @model_module = ModelModule.new(model_module_params)

          authorize! @model_module, with: ::Admin::ModelModulePolicy

          if @model_module.save
            if params[:model_id].present?
              ModuleHardpoint.find_or_create_by!(
                model_id: params[:model_id],
                model_module_id: @model_module.id
              )
            end

            render :show, status: :created
          else
            render json: ValidationError.new("model_module.create", errors: @model_module.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @model_module.update(model_module_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_module.update", errors: @model_module.errors), status: :bad_request
          end
        end

        def destroy
          @model_module.destroy

          head :no_content
        end

        def link
          model = Model.find(params[:model_id])

          ModuleHardpoint.find_or_create_by!(
            model_id: model.id,
            model_module_id: @model_module.id
          )

          render :show, status: :ok
        end

        def unlink
          model = Model.find(params[:model_id])

          hardpoint = ModuleHardpoint.find_by!(
            model_id: model.id,
            model_module_id: @model_module.id
          )
          hardpoint.destroy!

          render :show, status: :ok
        end

        private def set_model_module
          @model_module = ModelModule.find(params[:id])

          authorize! @model_module, with: ::Admin::ModelModulePolicy
        end

        private def model_module_params
          @model_module_params ||= params.permit(
            :name, :description, :manufacturer_id,
            :pledge_price, :production_status, :active, :hidden,
            :store_image
          )
        end

        private def model_module_query_params
          @model_module_query_params ||= params.permit(q: [
            :name_in, :id_eq, :name_cont, :name_eq,
            :module_hardpoints_model_id_eq, :module_hardpoints_model_id_not_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end

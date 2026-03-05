# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelModulePackagesController < ::Admin::Api::BaseController
        before_action :set_model_module_package, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::ModelModulePackagePolicy

          model_module_package_query_params["sorts"] = sorting_params(ModelModulePackage, model_module_package_query_params[:sorts], "created_at desc")

          @q = authorized_scope(ModelModulePackage.all).ransack(model_module_package_query_params)

          @model_module_packages = @q.result
            .includes(:model, :model_modules)
            .page(params[:page])
            .per(per_page(ModelModulePackage))
        end

        def show
        end

        def create
          @model_module_package = ModelModulePackage.new(model_module_package_params)

          authorize! @model_module_package, with: ::Admin::ModelModulePackagePolicy

          if @model_module_package.save
            sync_module_ids if params.key?(:module_ids)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_module_package.create", errors: @model_module_package.errors), status: :bad_request
          end
        end

        def update
          if @model_module_package.update(model_module_package_params)
            sync_module_ids if params.key?(:module_ids)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_module_package.update", errors: @model_module_package.errors), status: :bad_request
          end
        end

        def destroy
          @model_module_package.destroy

          head :no_content
        end

        private def set_model_module_package
          @model_module_package = ModelModulePackage.find(params[:id])

          authorize! @model_module_package, with: ::Admin::ModelModulePackagePolicy
        end

        private def model_module_package_params
          @model_module_package_params ||= params.permit(
            :name, :description, :model_id, :pledge_price,
            :active, :hidden,
            :store_image, :angled_view, :side_view, :top_view
          )
        end

        private def sync_module_ids
          incoming_ids = Array(params[:module_ids]).map(&:to_s)
          @model_module_package.model_module_ids = incoming_ids
        end

        private def model_module_package_query_params
          @model_module_package_query_params ||= params.permit(q: [
            :name_in, :id_eq, :name_cont, :name_eq, :model_id_eq, :sorts,
            sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end

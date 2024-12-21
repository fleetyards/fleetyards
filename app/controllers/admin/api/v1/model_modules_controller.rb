# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelModulesController < ::Admin::Api::BaseController
        def index
          authorize! :read, ModelModule

          model_module_query_params["sorts"] = "name asc"

          @q = ModelModule.ransack(model_module_query_params)

          @model_modules = @q.result
            .page(params[:page])
            .per(per_page(ModelModule))
        end

        private def model_module_query_params
          @model_module_query_params ||= query_params(
            :name_in, :id_eq, :name_cont, :name_eq
          )
        end
      end
    end
  end
end

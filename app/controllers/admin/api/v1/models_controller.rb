# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelsController < ::Admin::Api::BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.model", slug: params[:slug]))
        end

        def index
          authorize! :index, :admin_api_models

          @q = index_scope

          @models = @q.result
            .page(params[:page])
            .per(per_page(Model))
        end

        def options
          authorize! :index, :admin_api_models

          @q = index_scope

          @models = @q.result
            .page(params[:page])
            .per(per_page(Model))
        end

        private def index_scope
          model_query_params["sorts"] ||= sort_by_name

          Model.includes([:manufacturer]).ransack(model_query_params)
        end

        private def model_query_params
          @model_query_params ||= query_params(
            :name_cont, :sorts, :id_eq, name_in: [], sorts: [], id_not_in: []
          )
        end
      end
    end
  end
end

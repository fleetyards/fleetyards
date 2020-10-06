# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelsController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:models) }, only: [:index]
        after_action -> { pagination_header(:images) }, only: [:images]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t('messages.record_not_found.model', slug: params[:slug]))
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

        def images
          authorize! :show, :admin_api_models
          model = Model.find(params[:id])
          @images = model.images
            .order('images.created_at desc')
            .page(params[:page])
            .per(per_page(Image))
        end

        private def index_scope
          model_query_params['sorts'] = sort_by_name

          Model.ransack(model_query_params)
        end

        private def model_query_params
          @model_query_params ||= query_params(
            :name_cont, :sorts, name_in: [], sorts: [], id_not_in: []
          )
        end
      end
    end
  end
end

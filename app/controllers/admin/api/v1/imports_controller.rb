# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ImportsController < ::Admin::Api::BaseController
        before_action :set_import, only: [:show]

        def index
          authorize! :index, :admin_api_imports

          imports_query_params["sorts"] = "created_at desc"

          @q = Import.ransack(imports_query_params)

          @imports = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def show
          authorize! :show, @import
        end

        private def imports_query_params
          @imports_query_params ||= query_params(
            :type_eq, type_in: []
          )
        end

        private def set_import
          @import = Import.find(params[:id])
        end
      end
    end
  end
end

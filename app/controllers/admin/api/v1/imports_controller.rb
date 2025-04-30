# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ImportsController < ::Admin::Api::BaseController
        before_action :set_import, only: [:show]

        def index
          authorize! with: ::Admin::ImportPolicy

          imports_query_params["sorts"] = "created_at desc"

          @q = authorized_scope(Import.all).ransack(imports_query_params)

          @imports = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def show
        end

        private def imports_query_params
          @imports_query_params ||= query_params(
            :type_eq, type_in: []
          )
        end

        private def set_import
          @import = Import.find(params[:id])

          authorize! @import, with: ::Admin::ImportPolicy
        end
      end
    end
  end
end

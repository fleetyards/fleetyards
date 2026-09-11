# frozen_string_literal: true

module Api
  module V1
    class ImportsController < ::Api::BaseController
      after_action -> { pagination_header(:imports) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[cancel]

      before_action :set_import, only: %i[show cancel]

      def index
        authorize! with: ::ImportPolicy

        normalize_sort_params(import_query_params)
        import_query_params["sorts"] = sorting_params(Import, import_query_params["sorts"])

        @q = scope.ransack(import_query_params)
        @imports = @q.result
          .includes(:hangar_group)
          .page(params[:page])
          .per(per_page(Import))
      end

      def show
        authorize! @import, with: ::ImportPolicy
      end

      def cancel
        authorize! @import, with: ::ImportPolicy

        unless @import.request_cancel!
          render json: {code: "import.not_running", message: I18n.t("messages.import.not_running")}, status: :bad_request
          return
        end

        render :show
      end

      private def scope
        authorized_scope(Import.all)
      end

      private def set_import
        @import = scope.find(params[:id])
      end

      private def import_query_params
        @import_query_params ||= params.permit(q: [
          :aasm_state_eq, :type_eq, :s, :sorts, s: [], sorts: []
        ]).fetch(:q, {})
      end
    end
  end
end

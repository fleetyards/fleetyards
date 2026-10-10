# frozen_string_literal: true

module Api
  module V1
    class HangarRsiPageReportsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create]

      def create
        authorize! to: :update?, with: ::HangarPolicy

        ::RsiPageReport.record!(
          user: current_resource_owner,
          page: report_params[:page],
          check: report_params[:check],
          page_number: report_params[:page_number],
          extension_version: report_params[:extension_version],
          details: report_params[:details],
          markup: report_params[:markup]
        )

        head :no_content
      end

      private def report_params
        @report_params ||= params.permit(:page, :check, :page_number, :extension_version, details: [], markup: [])
      end
    end
  end
end

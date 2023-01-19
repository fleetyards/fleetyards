# frozen_string_literal: true

module Admin
  class MaintenanceController < ::Admin::ApplicationController
    def rsi_api_status
      authorize! :index, :admin_maintenance

      @active_nav = "admin-maintenance-rsi_api_status"

      @rsi_api_status = RsiRequestLog.where(resolved: false)
        .order(created_at: :desc)
        .all
    end
  end
end

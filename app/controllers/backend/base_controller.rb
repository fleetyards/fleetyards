module Backend
  class BaseController < ApplicationController
    before_filter :authenticate_user!
    before_filter :verify_admin

    def index
      authorize! :show, :backend
      @active_nav = 'backend'
      @worker_running = worker_running?
    end

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
    helper_method :sort_direction

    private def verify_admin
      redirect_to root_url unless current_user.try(:admin?)
    end
  end
end

# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :verify_admin

    def index
      authorize! :show, :admin
      @active_nav = 'admin'
      @worker_running = worker_running?
    end

    layout 'admin/application'

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
    helper_method :sort_direction

    private def verify_admin
      redirect_to root_url unless current_user.try(:admin?)
    end
  end
end

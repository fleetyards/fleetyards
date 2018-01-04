# frozen_string_literal: true

module Admin
  class BaseController < ::Admin::ApplicationController
    # before_action :verify_admin

    def index
      authorize! :show, :admin
      @active_nav = 'admin'
      @worker_running = worker_running?
    end

    layout 'admin/application'

    private def verify_admin
      return if current_user.try(:admin?)
      sign_out
      redirect_to root_url
    end
  end
end

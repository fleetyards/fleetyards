# frozen_string_literal: true

module Admin
  class BaseController < ::Admin::ApplicationController
    layout 'admin/application'

    def index
      authorize! :show, :admin
      @active_nav = 'admin'
      @worker_running = worker_running?
    end
  end
end

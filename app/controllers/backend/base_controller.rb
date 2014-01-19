module Backend
  class BaseController < ApplicationController
    before_filter :authenticate_user!
    before_filter :verify_admin

    def index
      authorize! :show, :backend
      @active_nav = 'backend'
      @settings = Setting.to_h

      @worker = WorkerState.where(name: "ShipsWorker").first
    end

    private def verify_admin
      redirect_to root_url unless current_user.try(:admin?)
    end
  end
end

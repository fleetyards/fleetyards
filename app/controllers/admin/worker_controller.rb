# frozen_string_literal: true

module Admin
  class WorkerController < ::Admin::ApplicationController
    def check_state
      authorize! :check, :worker
      respond_to do |format|
        format.js do
          render json: worker_running?(params[:name]), status: :ok
        end
        format.html do
          redirect_to root_path
        end
      end
    end
  end
end

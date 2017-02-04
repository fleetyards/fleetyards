# frozen_string_literal: true
module Backend
  class WorkerController < BaseController
    def check_state
      authorize! :check, :worker
      respond_to do |format|
        format.js do
          render json: worker_running?, status: :ok
        end
        format.html do
          redirect_to root_path
        end
      end
    end
  end
end

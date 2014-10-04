module Backend
  class WorkerController < BaseController

    def check_state
      authorize! :check, :worker
      respond_to do |format|
        format.js {
          render json: worker_running?, status: :ok
        }
        format.html {
          redirect_to root_path
        }
      end
    end
  end
end

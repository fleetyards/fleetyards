class WorkerController < ApplicationController

  def check_state
    authorize! :check, :worker
    respond_to do |format|
      format.js {
        worker_running = Resque.size(ENV['SHIPS_QUEUE']) != 0 || Resque.working.map(&:queues).flatten.include?(ENV['SHIPS_QUEUE'])
        render json: worker_running, status: :ok
      }
      format.html {
        redirect_to root_path
      }
    end
  end
end

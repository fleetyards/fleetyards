class WorkerController < ApplicationController

  def check_state
    authorize! :check, :worker
    respond_to do |format|
      format.js {
        render json: worker.running?, status: :ok
      }
      format.html {
        redirect_to root_path
      }
    end
  end

  private def worker
    @worker ||= WorkerState.where(name: params.fetch(:name, nil)).first
  end
end

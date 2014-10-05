class ServerErrorsController < ActionController::Base
  def server_error
    render "errors/error", status: 500, layout: "error"
  end
end

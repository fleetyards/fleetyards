class ErrorsController < ActionController::Base
  def not_found
    render status: 404, formats: [:html]
  end

  def server_error
    render status: 500, formats: [:html], layout: "error"
  end
end

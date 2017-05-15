# frozen_string_literal: true

class ServerErrorsController < ActionController::Base
  def server_error
    @action_name = action_name
    render "errors/error", status: 500, layout: "error"
  end
end

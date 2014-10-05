class ErrorsController < ApplicationController
  skip_authorization_check
  before_filter :authenticate_user!, only: []

  def not_found
    render "error", status: 404
  end

  def unprocessable_entity
    render "error", status: 422
  end
end

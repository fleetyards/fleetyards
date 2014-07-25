class ErrorsController < ApplicationController
  skip_authorization_check
  before_filter :authenticate_user!, only: []

  def not_found
    render :status => 404, :formats => [:html]
  end

  def server_error
    render :status => 500, :formats => [:html], layout: "error"
  end
end

module Api
  class BaseController < ActionController::Base
    check_authorization unless: :unauthorized_controllers
  end
end
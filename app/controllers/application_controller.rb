class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  add_flash_types :error, :warning

  check_authorization unless: :unauthorized_controllers

  private def unauthorized_controllers
    devise_controller?
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, warning: exception.message
  end

  before_filter :authenticate_user!, :set_default_nav

  private def set_default_nav
    @active_nav = 'home'
  end

  private def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
  helper_method :sort_direction

  private def backend?
    self.class.to_s.split("::").first=="Backend"
  end
  helper_method :backend?
end

class ApplicationController < ActionController::Base
  before_filter :configure_permitted_parameters, if: :devise_controller?

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

  private def registration_enabled?
    Settings.base.registration
  end
  helper_method :registration_enabled?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end
end

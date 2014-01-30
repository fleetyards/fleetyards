class ApplicationController < ActionController::Base
  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :authenticate_user!, :set_default_nav
  before_filter :set_locale

  protect_from_forgery with: :exception

  add_flash_types :error, :warning

  check_authorization unless: :unauthorized_controllers

  private def set_locale
    locale = current_user.locale if user_signed_in?
    if new_locale = params[:locale]
      if user_signed_in?
        current_user.update(locale: new_locale)
      end
      locale = new_locale
    end
    accept_language = request.env["HTTP_ACCEPT_LANGUAGE"]
    if accept_language.present? && match = accept_language.match(/#{I18n.available_locales.join('|')}/)
      locale ||= match[0]
    end
    I18n.locale = locale
  end

  private def default_url_options(options = {})
    {locale: I18n.locale}
  end

  private def unauthorized_controllers
    devise_controller? || is_a?(RailsAssetLocalization::LocalesController)
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, warning: exception.message
  end

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

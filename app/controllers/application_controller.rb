# frozen_string_literal: true
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, :set_default_nav
  before_action :set_locale

  protect_from_forgery with: :exception

  add_flash_types :error, :warning

  check_authorization unless: :unauthorized_controllers

  rescue_from ActionController::InvalidAuthenticityToken do
    @action_name = "unprocessable_entity"
    render "errors/error", status: 422
  end

  private def set_locale
    return unless request.env['HTTP_ACCEPT_LANGUAGE'].present?
    match = request.env['HTTP_ACCEPT_LANGUAGE'].match(/#{I18n.available_locales.join('|')}/)
    I18n.locale = match[0]
  end

  def worker_running?
    ship_queue = Sidekiq::Queue.new(ENV['SHIP_LOADER_QUEUE'] || 'fleetyards_ship_loader')
    process = Sidekiq::ProcessSet.new
    running_processes = process.sum { |ps| ps["busy"] }
    if !(ship_queue.size.zero? && running_processes.zero?)
      true
    else
      false
    end
  end

  private def default_url_options(_options = {})
    { locale: I18n.locale }
  end

  private def unauthorized_controllers
    devise_controller?
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, warning: exception.message
  end

  private def set_default_nav
    @active_nav = 'home'
  end

  private def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private def default_title
    @default_title ||= I18n.t(:"title.backend") if backend?
    @default_title ||= I18n.t(:"title.default")
  end
  helper_method :default_title

  private def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : 'desc'
  end
  helper_method :sort_direction

  private def backend?
    self.class.to_s.split('::').first == 'Backend'
  end
  helper_method :backend?

  private def registration_enabled?
    Rails.application.secrets[:registration]
  end
  helper_method :registration_enabled?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email, :password, :password_confirmation, :remember_me])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :username, :email, :password, :remember_me])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :email, :password, :password_confirmation, :current_password])
  end
end

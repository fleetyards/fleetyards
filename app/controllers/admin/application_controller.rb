# frozen_string_literal: true

module Admin
  class ApplicationController < ActionController::Base
    layout 'admin/application'

    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :authenticate_admin_user!, :set_default_nav
    before_action :set_locale

    protect_from_forgery with: :exception

    add_flash_types :error, :warning

    check_authorization unless: :unauthorized_controllers

    rescue_from ActionController::InvalidAuthenticityToken do
      @action_name = "unprocessable_entity"
      render "errors/error", status: 422
    end

    private def set_locale
      return if request.env['HTTP_ACCEPT_LANGUAGE'].blank?
      match = request.env['HTTP_ACCEPT_LANGUAGE'].match(/#{I18n.available_locales.join('|')}/)
      I18n.locale = match[0] unless match.nil?
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

    private def unauthorized_controllers
      devise_controller?
    end

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to root_url, warning: exception.message
    end

    private def set_default_nav
      @active_nav = 'home'
    end

    private def current_user
      current_admin_user
    end
    helper_method :current_user

    private def after_sign_out_path_for(_resource_or_scope)
      admin_root_path
    end

    def after_sign_in_path_for(_resource)
      admin_root_path
    end

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
    end
    helper_method :sort_direction

    private def registration_enabled?
      Rails.application.secrets[:registration]
    end
    helper_method :registration_enabled?

    protected

    def configure_permitted_parameters
      added_attrs = %i[username email password password_confirmation]
      devise_parameter_sanitizer.permit :sign_in, keys: %i[login password remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end
  end
end

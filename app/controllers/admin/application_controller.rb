# frozen_string_literal: true

module Admin
  class ApplicationController < ActionController::Base
    include RansackHelper

    layout 'admin/application'

    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :authenticate_admin_user!, :set_default_nav
    before_action :set_csrf_cookie

    protect_from_forgery with: :exception

    skip_before_action :track_ahoy_visit

    add_flash_types :error, :warning

    check_authorization unless: :unauthorized_controllers

    rescue_from ActionController::InvalidAuthenticityToken do
      @action_name = 'unprocessable_entity'
      render 'errors/error', status: :unprocessable_entity
    end

    def worker_running?
      model_queue = Sidekiq::Queue.new(ENV['MODEL_LOADER_QUEUE'] || 'fleetyards_model_loader')
      process = Sidekiq::ProcessSet.new
      running_processes = process.sum { |ps| ps['busy'] }
      if !(model_queue.size.zero? && running_processes.zero?)
        true
      else
        false
      end
    end

    private def unauthorized_controllers
      devise_controller?
    end

    rescue_from CanCan::AccessDenied do |exception|
      sign_out
      redirect_to new_admin_user_session_path, warning: exception.message
    end

    private def set_default_nav
      @active_nav = 'home'
    end

    private def current_user
      @current_user ||= current_admin_user
    end
    helper_method :current_user

    def current_ability
      @current_ability ||= AdminAbility.new(current_user)
    end

    private def after_sign_out_path_for(_resource_or_scope)
      admin_root_path
    end

    def after_sign_in_path_for(_resource)
      admin_root_path
    end

    protected def configure_permitted_parameters
      added_attrs = %i[username email password password_confirmation]
      devise_parameter_sanitizer.permit :sign_in, keys: %i[login password remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end

    private def set_csrf_cookie
      cookies['COMMAND-CSRF-TOKEN'] = { value: form_authenticity_token, domain: Rails.application.secrets[:cookie_domain] || :all, same_site: :none, secure: Rails.env.production? || Rails.env.staging? }
    end
  end
end

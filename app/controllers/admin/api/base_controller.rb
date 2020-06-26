# frozen_string_literal: true

module Admin
  module Api
    class BaseController < ActionController::API
      include ActionController::Cookies
      include ActionController::RequestForgeryProtection
      include ActionController::Caching
      include RansackHelper
      include Pagination

      protect_from_forgery with: :exception

      respond_to :json

      skip_before_action :track_ahoy_visit

      before_action :authenticate_admin_user!

      check_authorization

      rescue_from CanCan::AccessDenied do |exception|
        render json: { code: 'forbidden', message: exception.message }, status: :forbidden
      end

      rescue_from ActionController::InvalidAuthenticityToken do |_exception|
        render json: { code: 'invalid_authenticity_token', message: I18n.t('error_pages.unprocessable_entity') }, status: :unprocessable_entity
      end

      private def current_user
        @current_user ||= current_admin_user
      end
      helper_method :current_user

      def resource_message(resource, action, state)
        I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
      end

      private def not_found(message = I18n.t('messages.record_not_found.base'))
        render json: { code: 'not_found', message: message }, status: :not_found
      end
    end
  end
end

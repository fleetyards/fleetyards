# frozen_string_literal: true

module Admin
  module Api
    class BaseController < ActionController::API
      include ActionController::Caching
      include ActionPolicy::Controller
      include RansackHelper
      include Pagination

      helper_method :combined_fragment_cache_key
      helper_method :view_cache_dependencies

      respond_to :json

      skip_before_action :track_ahoy_visit

      before_action :authenticate_admin_user!

      verify_authorized

      authorize :user, through: :current_admin_user

      rescue_from ActionPolicy::Unauthorized do |exception|
        render json: {code: "forbidden", message: exception.result.message}, status: :forbidden
      end

      rescue_from ActionController::InvalidAuthenticityToken do |_exception|
        render json: {code: "invalid_authenticity_token", message: I18n.t("error_pages.unprocessable_entity")}, status: :unprocessable_entity
      end

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        render json: {code: "not_found", message: I18n.t("errors.not_found.message")}, status: :not_found
      end

      private def current_user
        @current_user ||= current_admin_user
      end
      helper_method :current_user

      def current_ability
        @current_ability ||= AdminAbility.new(current_user)
      end

      def resource_message(resource, action, state)
        I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
      end

      private def not_found(message = I18n.t("messages.record_not_found.base"))
        render json: {code: "not_found", message:}, status: :not_found
      end
    end
  end
end

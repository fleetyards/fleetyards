# frozen_string_literal: true

module Admin
  module Api
    # rubocop:disable Rails/ApplicationController
    class BaseController < ActionController::Base
      include RansackHelper
      include Concerns::Pagination

      protect_from_forgery with: :null_session
      respond_to :json

      skip_before_action :track_ahoy_visit

      before_action :authenticate_api_user!

      check_authorization

      rescue_from CanCan::AccessDenied do |exception|
        render json: { code: 'forbidden', message: exception.message }, status: :forbidden
      end

      private def current_user
        current_api_user
      end
      helper_method :current_user

      def resource_message(resource, action, state)
        I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
      end

      private def not_found(message = I18n.t('messages.record_not_found.base'))
        render json: { code: 'not_found', message: message }, status: :not_found
      end
    end
    # rubocop:enable Rails/ApplicationController
  end
end

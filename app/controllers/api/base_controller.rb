# frozen_string_literal: true

module Api
  # rubocop:disable Rails/ApplicationController
  class BaseController < ActionController::Base
    include RansackHelper
    include ActionController::HttpAuthentication::Token
    include Concerns::Pagination

    protect_from_forgery with: :null_session
    respond_to :json

    skip_before_action :track_ahoy_visit

    before_action :authenticate_api_user!, except: %i[root version]

    check_authorization except: %i[root version]

    after_action :set_rate_limit_headers

    rescue_from CanCan::AccessDenied do |exception|
      render json: { code: 'forbidden', message: exception.message }, status: :forbidden
    end

    def root
      respond_to do |format|
        format.html do
          redirect_to api_v1_root_path
        end
        format.json do
          render json: { message: 'FleetYards.net API root' }
        end
      end
    end

    def version
      render json: { version: Fleetyards::VERSION, codename: Fleetyards::CODENAME }
    end

    def current_user
      current_api_user
    end
    helper_method :current_user

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
    end

    private def not_found(message = I18n.t('messages.record_not_found.base'))
      render json: { code: 'not_found', message: message }, status: :not_found
    end

    private def set_rate_limit_headers
      return if request.env['rack.attack.throttle_data'].blank?

      match_data = request.env['rack.attack.throttle_data']['api']
      return if match_data.blank?

      now = Time.zone.now
      headers['X-RateLimit-Limit'] = match_data[:limit].to_s
      headers['X-RateLimit-Remaining'] = (match_data[:limit] - match_data[:count]).to_s
      headers['X-RateLimit-Reset'] = (now + (match_data[:period] - now.to_i % match_data[:period])).iso8601
    end
  end
  # rubocop:enable Rails/ApplicationController
end

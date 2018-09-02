# frozen_string_literal: true

module Api
  class BaseController < ActionController::Base
    include ActionController::HttpAuthentication::Token
    include Concerns::Pagination

    protect_from_forgery with: :null_session
    respond_to :json

    before_action :authenticate_api_user!, except: [:root]
    check_authorization except: [:root]

    after_action :set_rate_limit_headers
    after_action :set_renew_jwt_header

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
      headers['X-RateLimit-Reset'] = (now + (match_data[:period] - now.to_i % match_data[:period])).to_time.iso8601
    end

    private def set_renew_jwt_header
      return if jwt_token.blank?

      auth_token = AuthToken.find_by(
        key: jwt_token[:key],
        user_id: jwt_token[:user_id],
        token: jwt_token[:token]
      )

      return if auth_token.blank?

      headers['X-Renew-JWT'] = ::JsonWebToken.encode(auth_token.to_jwt_payload)
    end

    private def jwt_token
      return if current_user.blank?
      @jwt_token ||= begin
        auth_params, _options = token_and_options(request)
        ::JsonWebToken.decode(auth_params)
      end
    end

    private def query_params
      @query_params ||= begin
        q = JSON.parse(params[:q].to_s || '{}')
        q.transform_keys { |key| key.to_s.underscore }
      end
    rescue JSON::ParserError
      {}
    end
  end
end

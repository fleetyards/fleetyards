# encoding: utf-8
# frozen_string_literal: true

module Gql
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session
    respond_to :json

    after_action :set_rate_limit_headers

    def root
      redirect_to :gql_v1_root
    end

    def current_user
      warden.authenticate(scope: :api_user)
    end
    helper_method :current_user

    private def not_found(message = I18n.t('messages.record_not_found.base'))
      render json: { code: "not_found", message: message }, status: :not_found
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
  end
end

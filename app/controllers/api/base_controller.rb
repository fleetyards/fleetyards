# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    include ActionController::Cookies
    include ActionController::MimeResponds
    include ActionController::Caching
    include RansackHelper
    include Pagination

    helper_method :combined_fragment_cache_key
    helper_method :view_cache_dependencies

    respond_to :json

    skip_before_action :track_ahoy_visit

    before_action :authenticate_user!, except: %i[root version]
    before_action :current_ability
    before_action :set_locale
    before_action :set_last_active_at

    check_authorization except: %i[root version]

    after_action :set_rate_limit_headers

    rescue_from CanCan::AccessDenied do |exception|
      render json: {code: "forbidden", message: exception.message}, status: :forbidden
    end

    rescue_from ActionController::InvalidAuthenticityToken do |_exception|
      render json: {code: "invalid_authenticity_token", message: I18n.t("error_pages.unprocessable_entity")}, status: :unprocessable_entity
    end

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    rescue_from Pagination::MaxPerPageReached do |_exception|
      render json: {code: "pagination.max_per_page_reached", message: I18n.t("errors.pagination.max_per_page_reached")}, status: :bad_request
    end

    def current_ability
      @current_ability ||= Ability.new(current_user)
    end

    def access_cookie_valid?
      access_cookie = cookies.encrypted["#{Rails.configuration.cookie_prefix}_ACCESS_CONFIRMED"]

      access_cookie.present? && access_cookie == current_user.confirm_access_token
    end

    def root
      respond_to do |format|
        format.html do
          redirect_to api_v1_root_path
        end
        format.json do
          render json: {message: "#{Rails.configuration.app.name} API root"}
        end
      end
    end

    def version
      render json: {version: Fleetyards::VERSION, codename: Fleetyards::CODENAME}
    end

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t("resources.#{resource}"))
    end

    private def not_found(message = I18n.t("messages.record_not_found.base"))
      render json: {code: "not_found", message:}, status: :not_found
    end

    private def set_rate_limit_headers
      return if request.env["rack.attack.throttle_data"].blank?

      match_data = request.env["rack.attack.throttle_data"]["api"]
      return if match_data.blank?

      now = Time.zone.now
      headers["X-RateLimit-Limit"] = match_data[:limit].to_s
      headers["X-RateLimit-Remaining"] = (match_data[:limit] - match_data[:count]).to_s
      headers["X-RateLimit-Reset"] = (now + (match_data[:period] - (now.to_i % match_data[:period]))).iso8601
    end

    private def set_last_active_at
      return if current_user.blank?
      return if current_user.last_active_at.present? && current_user.last_active_at > 15.minutes.ago

      current_user.update(last_active_at: Time.current)
    end

    private def set_locale
      I18n.locale = extract_locale || I18n.default_locale
    end

    private def extract_locale
      parsed_locale = params[:locale] || request.env["HTTP_ACCEPT_LANGUAGE"] || ""

      AcceptLanguage.parse(parsed_locale).match(*I18n.available_locales)
    end
  end
end

# frozen_string_literal: true

module Api
  # Doorkeeper's metal endpoints -- userinfo, token info, discovery, dynamic
  # client registration -- inherit whatever `base_metal_controller` names, and
  # the gem's default is a bare `ActionController::API`. With
  # `handle_auth_errors :raise` that leaves an invalid token raising out of the
  # controller as a 500, where `Api::BaseController` turns the same errors into
  # a 401 for our own endpoints.
  #
  # Kept to the default plus that one rescue on purpose: everything
  # `Api::BaseController` adds -- cookies, caching, policies, ransack,
  # pagination -- is for our API, not for Doorkeeper's own flows.
  class BaseMetalController < ActionController::API
    rescue_from Doorkeeper::Errors::TokenUnknown,
      Doorkeeper::Errors::TokenExpired,
      Doorkeeper::Errors::TokenForbidden do |exception|
      render json: {code: "unauthorized", message: exception.message}, status: :unauthorized
    end
  end
end

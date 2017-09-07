# encoding: utf-8
# frozen_string_literal: true

require 'json_web_token'

module Api
  module V1
    class SessionsController < ::Api::V1::BaseController
      include ActionController::HttpAuthentication::Token

      skip_authorization_check
      before_action :authenticate_api_user!, except: [:create]

      def create
        resource = User.find_for_database_authentication(login: login_params[:login])
        return invalid_login_attempt unless resource

        if resource.valid_password?(login_params[:password])
          sign_in(:user, resource, store: false)
          render json: { token: ::JsonWebToken.encode(new_auth_token(resource.id).to_jwt_payload) }
          return
        end
        invalid_login_attempt
      end

      def destroy
        auth_token = AuthToken.find_by(user_id: current_user.id, token: jwt_token[:token])
        auth_token && auth_token.destroy
        render json: { code: "sessions.destroy", message: I18n.t("devise.sessions.signed_out") }
      end

      private def new_auth_token(user_id)
        @new_auth_token ||= begin
          AuthToken.create(
            user_id: user_id,
            user_agent: request.user_agent,
            description: login_params[:description],
            expires: login_params[:expires]
          )
        end
      end

      private def jwt_token
        @jwt_token ||= begin
          auth_params, _options = token_and_options(request)
          ::JsonWebToken.decode(auth_params)
        end
      end

      private def login_params
        @login_params ||= params.permit(:login, :password, :description, :expires)
      end

      private def invalid_login_attempt
        render json: { code: "session.create", message: I18n.t("devise.failure.invalid") }, status: :bad_request
      end
    end
  end
end

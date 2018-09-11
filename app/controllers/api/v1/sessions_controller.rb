# frozen_string_literal: true

require 'json_web_token'

module Api
  module V1
    class SessionsController < ::Api::V1::BaseController
      skip_authorization_check
      before_action :authenticate_api_user!, except: [:create]

      def create
        resource = User.find_for_database_authentication(login: login_params[:login])

        if resource.blank?
          render json: { code: 'session.create.not_found_in_database', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
          return
        else
          unless resource.confirmed?
            render json: { code: 'session.create.unconfirmed', message: I18n.t('devise.failure.unconfirmed') }, status: :bad_request
            return
          end

          unless resource.valid_password?(login_params[:password])
            render json: { code: 'session.create.invalid', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
            return
          end
        end

        sign_in(:user, resource, store: false)
        render json: { token: ::JsonWebToken.encode(new_auth_token(resource.id).to_jwt_payload) }
      end

      def renew
        auth_token = AuthToken.find_by!(user_id: current_user.id, user_agent: "#{user_agent.browser}-#{user_agent.platform}")
        auth_token.renew
        auth_token.reload
        render json: { token: ::JsonWebToken.encode(auth_token.to_jwt_payload) }
      end

      def destroy
        auth_token = AuthToken.find_by(user_id: current_user.id, user_agent: "#{user_agent.browser}-#{user_agent.platform}")
        auth_token&.destroy
        render json: { code: 'sessions.destroy', message: I18n.t('devise.sessions.signed_out') }
      end

      def destroy_all
        if AuthToken.where(user_id: current_user.id).destroy_all
          render json: { code: 'sessions.destroy_all', message: I18n.t('devise.sessions.signed_out_from_all') }
        else
          render json: { code: 'sessions.destroy_all.failed', message: I18n.t('devise.failure.could_not_sign_out_all') }
        end
      end

      private def new_auth_token(user_id)
        @new_auth_token ||= begin
          AuthToken.find_or_create_by(
            user_id: user_id,
            user_agent: "#{user_agent.browser}-#{user_agent.platform}"
          ) do |auth_token|
            auth_token.remember_me = params[:remember_me]
          end
        end
      end

      private def user_agent
        @user_agent ||= UserAgent.parse(request.user_agent)
      end

      private def login_params
        @login_params ||= params.permit(:login, :password, :remember_me)
      end

      private def invalid_login_attempt
        render json: { code: 'session.create', message: I18n.t('devise.failure.invalid') }, status: :bad_request
      end
    end
  end
end

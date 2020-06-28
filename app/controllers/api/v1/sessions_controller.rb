# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ::Api::BaseController
      skip_authorization_check
      before_action :authenticate_user!, except: [:create]

      def create
        resource = User.find_for_database_authentication(login: login_params[:login])

        if resource.blank?
          render json: { code: 'session.create.not_found_in_database', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
          return
        else
          unless resource.active_for_authentication?
            render json: { code: 'session.create.unconfirmed', message: I18n.t('devise.failure.unconfirmed') }, status: :bad_request
            return
          end

          unless resource.valid_password?(login_params[:password])
            render json: { code: 'session.create.invalid', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
            return
          end
        end

        resource.remember_me = login_params[:rememberMe]

        sign_in(:user, resource)

        render json: { success: true }
      end

      def destroy
        sign_out(:api_user)

        render json: { code: 'sessions.destroy', message: I18n.t('devise.sessions.signed_out') }
      end

      private def user_agent
        @user_agent ||= UserAgent.parse(request.user_agent)
      end

      private def login_params
        @login_params ||= params.permit(:login, :password, :rememberMe)
      end

      private def invalid_login_attempt
        render json: { code: 'session.create', message: I18n.t('devise.failure.invalid') }, status: :bad_request
      end
    end
  end
end

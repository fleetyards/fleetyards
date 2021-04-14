# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ::Api::BaseController
      skip_authorization_check except: [:confirm_access]
      before_action :authenticate_user!, except: [:create]

      def create
        resource = User.find_for_database_authentication(login: login_params[:login])

        if resource.blank?
          render json: { code: 'session.create.not_found_in_database', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
          return
        else
          unless resource.active_for_authentication?
            resource.resend_confirmation

            render json: { code: 'session.create.unconfirmed', message: I18n.t('devise.failure.unconfirmed') }, status: :bad_request
            return
          end

          if resource.otp_required_for_login && login_params[:twoFactorCode].blank?
            render json: { code: 'session.create.two_factor_required', message: I18n.t('devise.failure.two_factor_required') }, status: :bad_request
            return
          end

          unless resource.valid_password?(login_params[:password])
            render json: { code: 'session.create.invalid', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
            return
          end

          if resource.otp_required_for_login && !resource.validate_and_consume_otp!(login_params[:twoFactorCode])
            render json: { code: 'session.create.invalid', message: I18n.t('devise.failure.not_found_in_database') }, status: :bad_request
            return
          end
        end

        resource.remember_me = login_params[:rememberMe]

        sign_in(:user, resource)

        render json: { code: :success, message: I18n.t('labels.success') }
      end

      def destroy
        sign_out(:user)

        render json: { code: 'sessions.destroy', message: I18n.t('devise.sessions.signed_out') }
      end

      def confirm_access
        authorize! :confirm_access, current_user

        unless current_user.valid_password?(login_params[:password])
          render json: { code: 'session.confirmAccess.failure', message: I18n.t('messages.confirmAccess.failure') }, status: :bad_request
          return
        end

        cookies.encrypted["#{Rails.application.secrets[:cookie_prefix]}_ACCESS_CONFIRMED"] = {
          value: current_user.confirm_access_token,
          domain: Rails.application.secrets[:cookie_domain] || :all,
          secure: Rails.env.production? || Rails.env.staging?,
          expires: 15.minutes,
          httponly: true,
          same_site: :lax,
        }

        render json: { code: :success, message: I18n.t('labels.success') }
      end

      private def user_agent
        @user_agent ||= UserAgent.parse(request.user_agent)
      end

      private def login_params
        @login_params ||= params.permit(:login, :password, :rememberMe, :twoFactorCode)
      end

      private def invalid_login_attempt
        render json: { code: 'session.create', message: I18n.t('devise.failure.invalid') }, status: :bad_request
      end
    end
  end
end

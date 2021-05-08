# frozen_string_literal: true

module Api
  module V1
    class TwoFactorsController < ::Api::BaseController
      def qrcode
        authorize! :update, current_user

        current_user.update(otp_secret: User.generate_otp_secret) if current_user.otp_required_for_login?

        uri = current_user.otp_provisioning_uri(current_user.email, issuer: Rails.configuration.app.name)

        qr = RQRCode::QRCode.new(uri, level: :l)

        send_data qr.as_svg(color: 'ccc'), type: 'image/svg+xml', disposition: 'inline'
      end

      def enable
        authorize! :update, current_user

        unless access_cookie_valid?
          render json: { code: 'requires_access_confirmation', message: I18n.t('messages.user.requires_access_confirmation') }, status: :bad_request
          return
        end

        if current_user.otp_required_for_login?
          render json: { code: 'two_factor_setup.active', message: I18n.t('messages.user.two_factor_setup.active') }, status: :bad_request
          return
        end

        if current_user.validate_and_consume_otp!(params[:twoFactorCode])
          current_user.otp_required_for_login = true
          backup_codes = current_user.generate_otp_backup_codes!
          current_user.save!

          render json: { codes: backup_codes }
        else
          render json: { code: 'two_factor_setup.enable.failure', message: I18n.t('messages.user.two_factor_setup.enable.failure') }, status: :bad_request
        end
      end

      def disable
        authorize! :update, current_user

        unless access_cookie_valid?
          render json: { code: 'requires_access_confirmation', message: I18n.t('messages.user.requires_access_confirmation') }, status: :bad_request
          return
        end

        unless current_user.otp_required_for_login?
          render json: { code: 'two_factor_setup.inactive', message: I18n.t('messages.user.two_factor_setup.inactive') }, status: :bad_request
          return
        end

        if current_user.validate_and_consume_otp!(params[:twoFactorCode])
          current_user.otp_secret = User.generate_otp_secret
          current_user.otp_required_for_login = false
          current_user.save!

          render json: { code: :success, message: I18n.t('labels.success') }
        else
          render json: { code: 'two_factor_setup.disable.failure', message: I18n.t('messages.user.two_factor_setup.disable.failure') }, status: :bad_request
        end
      end

      def generate_backup_codes
        authorize! :update, current_user

        unless access_cookie_valid?
          render json: { code: 'requires_access_confirmation', message: I18n.t('messages.user.requires_access_confirmation') }, status: :bad_request
          return
        end

        unless current_user.otp_required_for_login?
          render json: { code: 'two_factor_setup.inactive', message: I18n.t('messages.user.two_factor_setup.inactive') }, status: :bad_request
          return
        end

        backup_codes = current_user.generate_otp_backup_codes!

        current_user.save!

        render json: { codes: backup_codes }
      end
    end
  end
end

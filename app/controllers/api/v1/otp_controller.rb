# frozen_string_literal: true

module Api
  module V1
    class OtpController < ::Api::BaseController
      def start
        authorize! current_user, to: :update?

        unless access_cookie_valid?
          render json: {code: "requires_access_confirmation", message: I18n.t("messages.user.requires_access_confirmation")}, status: :bad_request
          return
        end

        if current_user.otp_required_for_login?
          render json: {code: "otp.active", message: I18n.t("messages.otp.active")}, status: :bad_request
          return
        end

        current_user.update(otp_secret: User.generate_otp_secret)

        render json: {code: :success, message: I18n.t("labels.success")}
      end

      def qrcode
        authorize! current_user, to: :update?

        uri = current_user.otp_provisioning_uri(current_user.email, issuer: Rails.configuration.app.name)

        qr = RQRCode::QRCode.new(uri, level: :l)

        send_data qr.as_svg(color: "ccc"), type: "image/svg+xml", disposition: "inline"
      end

      def enable
        authorize! current_user, to: :update?

        unless access_cookie_valid?
          render json: {code: "requires_access_confirmation", message: I18n.t("messages.user.requires_access_confirmation")}, status: :bad_request
          return
        end

        if current_user.otp_required_for_login?
          render json: {code: "otp.active", message: I18n.t("messages.otp.active")}, status: :bad_request
          return
        end

        if current_user.validate_and_consume_otp!(otp_params[:otp_code])
          current_user.otp_required_for_login = true
          backup_codes = current_user.generate_otp_backup_codes!
          current_user.save!

          render json: {codes: backup_codes}
        else
          render json: {code: "otp.enable.failure", message: I18n.t("messages.otp.enable.failure")}, status: :bad_request
        end
      end

      def disable
        authorize! current_user, to: :update?

        unless access_cookie_valid?
          render json: {code: "requires_access_confirmation", message: I18n.t("messages.user.requires_access_confirmation")}, status: :bad_request
          return
        end

        unless current_user.otp_required_for_login?
          render json: {code: "otp.inactive", message: I18n.t("messages.otp.inactive")}, status: :bad_request
          return
        end

        if current_user.validate_and_consume_otp!(otp_params[:otp_code]) || current_user.invalidate_otp_backup_code!(otp_params[:otp_code])
          current_user.otp_secret = User.generate_otp_secret
          current_user.otp_required_for_login = false
          current_user.save!

          render json: {code: :success, message: I18n.t("labels.success")}
        else
          render json: {code: "otp.disable.failure", message: I18n.t("messages.otp.disable.failure")}, status: :bad_request
        end
      end

      def generate_backup_codes
        authorize! current_user, to: :update?

        unless access_cookie_valid?
          render json: {code: "requires_access_confirmation", message: I18n.t("messages.user.requires_access_confirmation")}, status: :bad_request
          return
        end

        unless current_user.otp_required_for_login?
          render json: {code: "otp.inactive", message: I18n.t("messages.otp.inactive")}, status: :bad_request
          return
        end

        backup_codes = current_user.generate_otp_backup_codes!

        current_user.save!

        render json: {codes: backup_codes}
      end

      private def otp_params
        @otp_params ||= params.transform_keys(&:underscore)
          .permit(:otp_code)
      end
    end
  end
end

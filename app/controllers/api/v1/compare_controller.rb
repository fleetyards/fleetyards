# frozen_string_literal: true

module Api
  module V1
    class CompareController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []

      def share
        slugs = share_params[:models].to_a.map(&:to_s)

        if slugs.empty?
          render json: ValidationError.new("compare.share", message: I18n.t("errors.messages.compare.share.empty")), status: :bad_request
          return
        end

        if slugs.size > CompareImage::MAX_SHARE_MODELS
          render json: ValidationError.new("compare.share", message: I18n.t("errors.messages.compare.share.too_many", max: CompareImage::MAX_SHARE_MODELS)), status: :bad_request
          return
        end

        record = CompareImage.find_or_create_for_share(slugs)

        if record.blank? || record.share_key.blank?
          render json: ValidationError.new("compare.share", message: I18n.t("errors.messages.compare.share.unknown_models")), status: :bad_request
          return
        end

        canonical_slugs = record.share_key.split(CompareImage::SHARE_KEY_SEPARATOR)
        long_url = frontend_compare_url(models: canonical_slugs)
        short_url = build_short_url(record.short_code) || long_url

        render json: {shortUrl: short_url, longUrl: long_url}
      end

      private def share_params
        @share_params ||= params.permit(models: [])
      end

      private def build_short_url(short_code)
        return nil if short_code.blank?

        host = Rails.configuration.app.short_domain
        return nil if host.blank?

        scheme = Rails.configuration.force_ssl ? "https" : "http"
        "#{scheme}://#{host}/c/#{short_code}"
      end
    end
  end
end

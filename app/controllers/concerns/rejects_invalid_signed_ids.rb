# frozen_string_literal: true

# A signed id that does not verify was altered, or signed under another key.
module RejectsInvalidSignedIds
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveSupport::MessageVerifier::InvalidSignature do |_exception|
      render json: {code: "invalid_signed_id", message: I18n.t("error_pages.unprocessable_entity")}, status: :bad_request
    end
  end
end

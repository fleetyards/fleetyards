# frozen_string_literal: true

module Kofi
  # Ko-fi's webhook. Every payment arrives here as a form-encoded POST with the
  # whole payload as JSON in a single `data` field. There is no session, no
  # cookie and no user.
  #
  # Inherits ActionController::Base rather than ApplicationController for the
  # same reason Discord::InteractionsController does: ApplicationController adds
  # HTTP basic auth whenever basic_auth.password is set, which is how staging is
  # protected, and Ko-fi cannot supply those credentials.
  class WebhooksController < ActionController::Base
    skip_forgery_protection

    def create
      return head :unauthorized unless verified?

      ::Kofi::PaymentImporter.call(payload)

      head :ok
    end

    # Ko-fi sends a token it shows the creator in its own settings; it is the
    # only thing separating a real payment from anyone who knows the URL.
    #
    # A missing or unparseable body answers 401 rather than 400: it cannot be
    # verified, and an unauthenticated endpoint has nothing to gain from telling
    # a caller which half of the request was wrong.
    private def verified?
      return false if expected_token.blank?

      supplied = payload["verification_token"].to_s
      return false if supplied.empty?

      ActiveSupport::SecurityUtils.secure_compare(supplied, expected_token)
    end

    private def expected_token
      Rails.application.credentials.dig(:kofi, :verification_token).to_s
    end

    private def payload
      @payload ||= JSON.parse(params[:data].to_s)
    rescue JSON::ParserError
      @payload = {}
    end
  end
end

# frozen_string_literal: true

module OauthTestHelpers
  def oauth_headers_for(user, scopes:, with_access_confirmation: false)
    token = create(:oauth_access_token, resource_owner_id: user.id, scopes: scopes)
    headers = {"Authorization" => "Bearer #{token.token}"}
    headers["X-Access-Confirmation"] = access_confirmation_token_for(user) if with_access_confirmation
    headers
  end

  def access_confirmation_token_for(user)
    verifier = ActiveSupport::MessageVerifier.new(
      Rails.application.credentials.confirm_access_secret!,
      purpose: :access_confirmation
    )
    verifier.generate(user.id, expires_in: 15.minutes)
  end
end

module ActionDispatch
  class IntegrationTest
    include OauthTestHelpers
  end
end

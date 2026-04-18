# frozen_string_literal: true

module AccessConfirmable
  extend ActiveSupport::Concern

  def issue_access_confirmation(user)
    if doorkeeper_token
      token = access_confirmation_verifier.generate(user.id, expires_in: 30.minutes)
      {token:}
    else
      cookies.encrypted["#{Rails.configuration.cookie_prefix}_ACCESS_CONFIRMED"] = {
        value: user.confirm_access_token,
        domain: Rails.configuration.app.cookie_domain,
        secure: Rails.env.production? || Rails.env.staging?,
        expires: 30.minutes,
        httponly: true,
        same_site: :lax
      }
      {}
    end
  end
end

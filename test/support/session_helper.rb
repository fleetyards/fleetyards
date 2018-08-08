# frozen_string_literal: true

module SessionHelper
  def add_authorization(user)
    @request.env['HTTP_AUTHORIZATION'] = http_authorization(user)
  end

  def http_authorization(user)
    token = AuthToken.find_or_create_by(user_id: user.id)
    jwt = JsonWebToken.encode(token.to_jwt_payload)
    ActionController::HttpAuthentication::Token.encode_credentials(jwt)
  end
end

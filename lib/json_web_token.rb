# encoding: utf-8
# frozen_string_literal: true

module JsonWebToken
  module_function

  def encode(payload)
    payload = payload.dup
    payload[:iss] = "Reckoning.io"

    JWT.encode(payload, Rails.application.secrets[:devise_jwt])
  end

  def decode(token)
    decoded_token = JWT.decode(token, Rails.application.secrets[:devise_jwt])
    HashWithIndifferentAccess.new(decoded_token.first)
  rescue
    nil
  end
end

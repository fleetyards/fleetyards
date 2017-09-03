# encoding: utf-8
# frozen_string_literal: true

module JsonWebToken
  module_function

  def encode(payload)
    payload = payload.dup
    payload[:iss] = "FleetYards.net"

    JWT.encode(payload, Rails.application.secrets[:devise_jwt], 'HS512')
  end

  def decode(token)
    decoded_token = JWT.decode(token, Rails.application.secrets[:devise_jwt], true, algorithm: 'HS512')
    HashWithIndifferentAccess.new(decoded_token.first)
  rescue => e
    Rails.logger.error e.to_yaml
    nil
  end
end

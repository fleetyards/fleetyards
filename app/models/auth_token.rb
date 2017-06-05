# encoding: utf-8
# frozen_string_literal: true

require "json_web_token"

class AuthToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true

  before_validation :generate_authentication_token, on: :create

  def to_jwt_payload
    {
      token: token,
      user_id: user_id,
      exp: expires
    }.compact
  end

  private def generate_authentication_token
    loop do
      auth_token = Devise.friendly_token
      next if AuthToken.find_by(user_id: user_id, token: auth_token)
      self.token = auth_token
      break
    end
  end
end

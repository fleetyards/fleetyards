# frozen_string_literal: true

require 'json_web_token'

class AuthToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true

  before_validation :generate_authentication_token, on: :create

  def self.cleanup
    AuthToken.order(created_at: :desc).group_by(&:user_id).each do |_user_id, user_auth_tokens|
      next if user_auth_tokens.count == 1
      user_auth_tokens.group_by(&:key).each do |_key, auth_tokens|
        next if auth_tokens.count == 1
        auth_tokens.each_with_index do |auth_token, index|
          next if index.zero?
          auth_token.destroy
        end
      end
    end
  end

  def to_jwt_payload
    {
      token: token,
      user_id: user_id,
      exp: Time.zone.now.to_i + expires,
      key: key
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

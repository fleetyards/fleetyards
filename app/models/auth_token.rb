# frozen_string_literal: true

require 'json_web_token'

class AuthToken < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  before_create :set_expires_at

  def self.expired
    where('expires_at < ?', Time.zone.now)
  end

  def set_expires_at
    self.expires_at = Time.zone.now + (permanent? ? 30.days : 30.minutes)
  end

  def renew
    set_expires_at
    save
  end

  def to_jwt_payload
    {
      user: user_id,
      client_key: client_key,
      exp: expires_at.to_i
    }.compact
  end
end

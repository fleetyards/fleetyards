# frozen_string_literal: true

require 'json_web_token'

class AuthToken < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  before_create :set_expires_at
  before_create :generate_client_key

  ransack_alias :name, :name_or_slug

  def self.expired
    where('expires_at < ?', Time.zone.now)
  end

  def self.valid
    where('expires_at > ?', Time.zone.now)
  end

  def set_expires_at
    self.expires_at = Time.zone.now + (permanent? ? 14.days : 30.minutes)
  end

  def renew
    set_expires_at
    save
  end

  def to_jwt_payload
    reload
    {
      user: user_id,
      client_key: client_key,
      exp: expires_at.to_i
    }.compact
  end

  private def generate_client_key
    self.client_key = SecureRandom.hex(64)
  end
end

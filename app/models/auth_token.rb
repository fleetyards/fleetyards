# frozen_string_literal: true

# == Schema Information
#
# Table name: auth_tokens
#
#  id          :uuid             not null, primary key
#  description :string
#  expired_at  :datetime
#  token       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid
#
# Indexes
#
#  index_auth_tokens_on_token    (token) UNIQUE
#  index_auth_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class AuthToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :description, presence: true

  paginates_per 30

  def generate_token
    new_token = nil

    self.token = loop do
      new_token = Devise.friendly_token

      new_hash = Devise::Encryptor.digest(self.class, new_token)

      break new_hash unless self.class.exists?(token: new_hash)
    end

    new_token
  end

  def expired?
    expired_at.present? && expired_at < Time.current
  end

  def self.pepper
    Devise.pepper
  end

  def self.stretches
    Devise.stretches
  end
end

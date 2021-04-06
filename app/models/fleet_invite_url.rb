# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_invite_urls
#
#  id            :uuid             not null, primary key
#  expires_after :datetime
#  limit         :integer
#  token         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  fleet_id      :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_fleet_invite_urls_on_token  (token) UNIQUE
#
class FleetInviteUrl < ApplicationRecord
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::DateHelper

  paginates_per 30

  belongs_to :fleet
  belongs_to :user

  validates :token,
            uniqueness: true,
            presence: true

  before_validation :generate_token

  def self.active
    where(
      %{
        (fleet_invite_urls.expires_after >= :time_now OR fleet_invite_urls.expires_after IS NULL)
        AND (fleet_invite_urls.limit > 0 OR fleet_invite_urls.limit IS NULL)
      },
      time_now: Time.zone.now
    )
  end

  def expired?
    return false if expires_after.nil?

    expires_after < Time.zone.now
  end

  def expires_after_label
    return nil if expires_after.blank?

    distance_of_time_in_words(Time.zone.now.utc, expires_after.utc)
  end

  def limit_reached?
    return false if limit.nil?

    limit <= 0
  end

  def reduce_limit
    return if limit.blank? || limit_reached?

    update(limit: limit - 1)
  end

  def url
    return short_fleet_invite_url(token: token) if Rails.application.secrets[:short_domain].present?

    frontend_fleet_invite_url(token: token)
  end

  private def generate_token
    return if token.present?

    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(7, false)

      break random_token unless self.class.exists?(token: random_token)
    end
  end
end

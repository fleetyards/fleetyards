# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_invite_urls
#
#  id         :uuid             not null, primary key
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  fleet_id   :uuid
#  user_id    :uuid
#
# Indexes
#
#  index_fleet_invite_urls_on_token_and_fleet_id  (token,fleet_id) UNIQUE
#
class FleetInviteUrl < ApplicationRecord
  include Rails.application.routes.url_helpers

  paginates_per 30

  belongs_to :fleet
  belongs_to :user
  has_many :fleet_memberships, dependent: :nullify

  validates :token,
            uniqueness: { scope: :fleet_id },
            presence: true

  before_validation :generate_token

  def url
    frontend_fleet_invite_url(slug: fleet.slug, token: token)
  end

  def invite_count
    fleet_memberships.size
  end

  private def generate_token
    return if token.present?

    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless self.class.exists?(fleet_id: fleet_id, token: random_token)
    end
  end
end

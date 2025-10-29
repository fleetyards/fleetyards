# == Schema Information
#
# Table name: omniauth_connections
#
#  id           :uuid             not null, primary key
#  auth_payload :jsonb
#  provider     :integer          not null
#  uid          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_omniauth_connections_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class OmniauthConnection < ApplicationRecord
  belongs_to :user

  enum :provider, {
    google_oauth2: 0,
    discord: 1,
    github: 2,
    bluesky: 3
  }

  validates :provider, presence: true, uniqueness: {scope: :user_id}
end

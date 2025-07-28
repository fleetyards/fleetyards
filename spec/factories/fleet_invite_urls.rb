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
FactoryBot.define do
  factory :fleet_invite_url do
    fleet
    user
  end
end

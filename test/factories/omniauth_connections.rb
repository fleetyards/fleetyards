# frozen_string_literal: true

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
FactoryBot.define do
  factory :omniauth_connection do
    user
    uid { SecureRandom.hex(10) }
    provider { :discord }
    auth_payload { {provider: provider.to_s, uid: uid, info: {email: user.email}} }
  end
end

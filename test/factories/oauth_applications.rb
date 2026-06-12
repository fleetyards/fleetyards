# == Schema Information
#
# Table name: oauth_applications
#
#  id           :uuid             not null, primary key
#  confidential :boolean          default(TRUE), not null
#  name         :string           not null
#  owner_type   :string
#  redirect_uri :text
#  scopes       :string           default(""), not null
#  secret       :string(512)      not null
#  uid          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  owner_id     :uuid
#
# Indexes
#
#  index_oauth_applications_on_owner_id_and_owner_type  (owner_id,owner_type)
#  index_oauth_applications_on_uid                      (uid) UNIQUE
#
FactoryBot.define do
  factory :oauth_application, class: Oauth::Application do
    name { Faker::Company.name }
    uid { Faker::Alphanumeric.alphanumeric(number: 40) }
    secret { Faker::Alphanumeric.alphanumeric(number: 40) }
    confidential { true }
    scopes {
      [
        "public", "profile:read", "profile:write", "hangar", "hangar:read", "hangar:write", "fleet",
        "fleet:read", "fleet:write"
      ]
    }
    owner { create(:user) }
    redirect_uri { "#{Faker::Internet.url(scheme: "https")}\n#{Faker::Internet.url(scheme: "https")}" }
  end
end

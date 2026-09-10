# == Schema Information
#
# Table name: oauth_applications
#
#  id               :uuid             not null, primary key
#  aasm_state       :string           default("pending"), not null
#  approved_at      :datetime
#  confidential     :boolean          default(TRUE), not null
#  name             :string           not null
#  owner_type       :string
#  redirect_uri     :text
#  rejected_at      :datetime
#  rejection_reason :text
#  scopes           :string           default(""), not null
#  secret           :string(512)      not null
#  uid              :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :uuid
#  reviewed_by_id   :uuid
#
# Indexes
#
#  index_oauth_applications_on_aasm_state               (aasm_state)
#  index_oauth_applications_on_owner_id_and_owner_type  (owner_id,owner_type)
#  index_oauth_applications_on_reviewed_by_id           (reviewed_by_id)
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

    # Approved by default: almost every test is about what a working client
    # does, and the review gate is its own handful of tests rather than a
    # precondition every one of them has to restate.
    aasm_state { "approved" }
    approved_at { Time.zone.now }

    trait :pending do
      aasm_state { "pending" }
      approved_at { nil }
    end

    trait :rejected do
      aasm_state { "rejected" }
      approved_at { nil }
      rejected_at { Time.zone.now }
      rejection_reason { "Redirect target is not under the stated domain" }
    end
  end
end

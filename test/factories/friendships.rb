# frozen_string_literal: true

# == Schema Information
#
# Table name: friendships
#
#  id           :uuid             not null, primary key
#  aasm_state   :string           default("pending"), not null
#  accepted_at  :datetime
#  declined_at  :datetime
#  ignored_at   :datetime
#  withdrawn_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  addressee_id :uuid             not null
#  requester_id :uuid             not null
#
# Indexes
#
#  index_friendships_on_addressee_id       (addressee_id)
#  index_friendships_on_pair               (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)) UNIQUE
#  index_friendships_on_pending_addressee  (addressee_id) WHERE ((aasm_state)::text = 'pending'::text)
#  index_friendships_on_requester_id       (requester_id)
#
# Foreign Keys
#
#  fk_rails_...  (addressee_id => users.id) ON DELETE => cascade
#  fk_rails_...  (requester_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :friendship do
    association :requester, factory: :user
    association :addressee, factory: :user

    trait :accepted do
      aasm_state { "accepted" }
      accepted_at { Time.zone.now }
    end

    trait :declined do
      aasm_state { "declined" }
      declined_at { Time.zone.now }
    end

    trait :ignored do
      aasm_state { "ignored" }
      ignored_at { Time.zone.now }
    end
  end
end

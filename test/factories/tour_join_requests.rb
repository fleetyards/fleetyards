# frozen_string_literal: true

# == Schema Information
#
# Table name: tour_join_requests
#
#  id            :uuid             not null, primary key
#  aasm_state    :string           default("pending"), not null
#  decided_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  decided_by_id :uuid
#  tour_id       :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_tour_join_requests_on_decided_by_id          (decided_by_id)
#  index_tour_join_requests_on_pending_tour_and_user  (tour_id,user_id) UNIQUE WHERE ((aasm_state)::text = 'pending'::text)
#  index_tour_join_requests_on_tour_id                (tour_id)
#  index_tour_join_requests_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (decided_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (tour_id => tours.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :tour_join_request do
    association :tour, factory: [:tour, :for_fleet]
    association :user, factory: :user

    trait :approved do
      aasm_state { "approved" }
      decided_at { Time.current }
    end

    trait :declined do
      aasm_state { "declined" }
      decided_at { Time.current }
    end
  end
end

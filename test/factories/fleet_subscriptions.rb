# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_subscriptions
#
#  id                        :uuid             not null, primary key
#  ended_at                  :date
#  granted_via               :string           default("manual"), not null
#  note                      :text
#  started_at                :date             not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  fleet_id                  :uuid             not null
#  supporter_contribution_id :uuid
#
# Indexes
#
#  idx_on_fleet_id_started_at_ended_at_8e188918c2          (fleet_id,started_at,ended_at)
#  index_fleet_subscriptions_on_active_fleet               (fleet_id) UNIQUE WHERE (ended_at IS NULL)
#  index_fleet_subscriptions_on_supporter_contribution_id  (supporter_contribution_id) WHERE (supporter_contribution_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (supporter_contribution_id => supporter_contributions.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :fleet_subscription do
    fleet
    started_at { Date.current }
    granted_via { "manual" }

    trait :seeded do
      granted_via { "contribution" }
      supporter_contribution
    end

    trait :closed do
      ended_at { Date.current }
    end
  end
end

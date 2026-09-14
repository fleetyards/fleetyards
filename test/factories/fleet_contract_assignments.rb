# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_contract_assignments
#
#  id                :uuid             not null, primary key
#  aasm_state        :string           default("requested"), not null
#  accepted_at       :datetime
#  declined_at       :datetime
#  removed_at        :datetime
#  requested_at      :datetime
#  role              :integer          default(1), not null
#  withdrawn_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  approved_by_id    :uuid
#  fleet_contract_id :uuid             not null
#  user_id           :uuid             not null
#
# Indexes
#
#  idx_on_fleet_contract_id_user_id_cd14b5f8cd             (fleet_contract_id,user_id) UNIQUE
#  index_fleet_contract_assignments_on_accepted_lead       (fleet_contract_id) UNIQUE WHERE ((role = 0) AND ((aasm_state)::text = 'accepted'::text))
#  index_fleet_contract_assignments_on_approved_by_id      (approved_by_id)
#  index_fleet_contract_assignments_on_contract_and_state  (fleet_contract_id,aasm_state)
#  index_fleet_contract_assignments_on_fleet_contract_id   (fleet_contract_id)
#  index_fleet_contract_assignments_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (fleet_contract_id => fleet_contracts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :fleet_contract_assignment do
    fleet_contract
    user
    role { :crew }

    trait :lead do
      role { :lead }
      aasm_state { "accepted" }
      accepted_at { Time.current }
    end

    trait :accepted do
      aasm_state { "accepted" }
      accepted_at { Time.current }
    end
  end
end

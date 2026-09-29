# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_fid_claims
#
#  id                  :uuid             not null, primary key
#  cancel_reason       :string
#  cancelled_at        :datetime
#  completed_at        :datetime
#  created_by          :uuid
#  ends_at             :datetime         not null
#  fid                 :string           not null
#  holder_new_fid      :string
#  holder_previous_fid :string
#  state               :string           default("open"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  claimant_id         :uuid             not null
#  holder_id           :uuid
#
# Indexes
#
#  index_fleet_fid_claims_on_claimant_id        (claimant_id)
#  index_fleet_fid_claims_on_holder_id          (holder_id)
#  index_fleet_fid_claims_on_open_fid           (fid) UNIQUE WHERE ((state)::text = 'open'::text)
#  index_fleet_fid_claims_on_state_and_ends_at  (state,ends_at)
#
# Foreign Keys
#
#  fk_rails_...  (claimant_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (holder_id => fleets.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :fleet_fid_claim do
    claimant { association :fleet, :rsi_verified, rsi_sid: "CLAIM" }
    holder { association :fleet, fid: claimant.rsi_verified_sid }
    fid { claimant.rsi_verified_sid }
    ends_at { FleetFidClaim::GRACE_PERIOD.from_now }
  end
end

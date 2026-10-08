# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_fid_claim do
    claimant { association :fleet, :rsi_verified, rsi_sid: "CLAIM" }
    holder { association :fleet, fid: claimant.rsi_verified_sid }
    fid { claimant.rsi_verified_sid }
    ends_at { FleetFidClaim::GRACE_PERIOD.from_now }
  end
end

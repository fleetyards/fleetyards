# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_squadron_membership do
    fleet_squadron
    fleet_membership { association :fleet_membership, :accepted, fleet: fleet_squadron.fleet }
  end
end

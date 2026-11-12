# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_squadron_ship_request do
    fleet_squadron_membership
    vehicle { association :vehicle, user: fleet_squadron_membership.fleet_membership.user }
  end
end

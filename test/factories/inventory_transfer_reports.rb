# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_transfer_report do
    association :inventory_transfer, factory: %i[inventory_transfer to_user]
    association :reporter, factory: :user
    reason { :spam }
  end
end

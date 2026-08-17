# frozen_string_literal: true

# == Schema Information
#
# Table name: funding_goals
#
#  id             :uuid             not null, primary key
#  amount_cents   :integer          not null
#  currency       :string           default("EUR"), not null
#  description    :text
#  effective_from :date             not null
#  ended_at       :date
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_funding_goals_on_effective_from  (effective_from)
#  index_funding_goals_on_ended_at        (ended_at)
#
FactoryBot.define do
  factory :funding_goal do
    sequence(:title) { |n| "Funding goal ##{n}" }
    amount_cents { 10_000 }
    currency { "EUR" }
    effective_from { Date.current }

    trait :ended do
      ended_at { Date.current }
    end

    trait :server_costs do
      title { "Server costs" }
      description { "VPS and database hosting" }
    end
  end
end

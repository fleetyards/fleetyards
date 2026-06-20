# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id           :uuid             not null, primary key
#  amount_cents :integer          not null
#  anonymous    :boolean          default(FALSE), not null
#  currency     :string           default("EUR"), not null
#  ended_at     :date
#  name         :string
#  note         :text
#  recurring    :boolean          default(FALSE), not null
#  started_at   :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_supporter_contributions_on_recurring_and_ended_at  (recurring,ended_at)
#  index_supporter_contributions_on_started_at              (started_at)
#
FactoryBot.define do
  factory :supporter_contribution do
    sequence(:name) { |n| "Supporter #{n}" }
    amount_cents { 500 }
    currency { "EUR" }
    anonymous { false }
    recurring { false }
    started_at { Date.current }

    trait :anonymous do
      anonymous { true }
    end

    trait :recurring do
      recurring { true }
      ended_at { nil }
    end
  end
end

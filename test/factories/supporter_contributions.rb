# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id                  :uuid             not null, primary key
#  amount_cents        :integer          not null
#  anonymous           :boolean          default(FALSE), not null
#  currency            :string           default("EUR"), not null
#  ended_at            :date
#  name                :string
#  note                :text
#  payer_email         :string
#  recurring           :boolean          default(FALSE), not null
#  source              :string           default("manual"), not null
#  source_amount_cents :integer
#  source_currency     :string
#  started_at          :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kofi_transaction_id :string
#  patreon_member_id   :string
#  patreon_user_id     :string
#  user_id             :uuid
#
# Indexes
#
#  index_supporter_contributions_on_kofi_transaction_id     (kofi_transaction_id) UNIQUE WHERE (kofi_transaction_id IS NOT NULL)
#  index_supporter_contributions_on_patreon_member_id       (patreon_member_id) UNIQUE WHERE (patreon_member_id IS NOT NULL)
#  index_supporter_contributions_on_patreon_user_id         (patreon_user_id) WHERE (patreon_user_id IS NOT NULL)
#  index_supporter_contributions_on_payer_email             (payer_email) WHERE (payer_email IS NOT NULL)
#  index_supporter_contributions_on_recurring_and_ended_at  (recurring,ended_at)
#  index_supporter_contributions_on_started_at              (started_at)
#  index_supporter_contributions_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
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

    trait :patreon do
      source { "patreon" }
      sequence(:patreon_member_id) { |n| "member-#{n}" }
      recurring { true }
      anonymous { true }
    end

    trait :kofi do
      source { "kofi" }
      sequence(:kofi_transaction_id) { |n| "kofi-txn-#{n}" }
      recurring { false }
    end
  end
end

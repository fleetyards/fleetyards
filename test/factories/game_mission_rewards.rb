# frozen_string_literal: true

# == Schema Information
#
# Table name: game_mission_rewards
#
#  id                    :uuid             not null, primary key
#  amount                :integer
#  badge                 :string
#  currency              :string
#  entity_class          :string
#  entity_name           :string
#  kind                  :string           not null
#  max                   :integer
#  org_key               :string
#  org_name              :string
#  position              :integer          not null
#  weight                :decimal(8, 3)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  game_mission_build_id :uuid             not null
#
# Indexes
#
#  index_game_mission_rewards_on_build               (game_mission_build_id)
#  index_game_mission_rewards_on_build_and_position  (game_mission_build_id,position) UNIQUE
#  index_game_mission_rewards_on_kind                (kind)
#
# Foreign Keys
#
#  fk_rails_...  (game_mission_build_id => game_mission_builds.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :game_mission_reward do
    build factory: :game_mission_build
    kind { "reputation" }
    amount { 100 }
    org_key { "factionreputation_lawful_foxwellenforcement" }
    org_name { "Foxwell Enforcement" }
    sequence(:position) { |n| n }

    # One of the eight contracts in 4.10.1 that state a figure at all.
    trait :currency do
      kind { "currency" }
      amount { 40_000 }
      currency { "UEC" }
      org_key { nil }
      org_name { nil }
    end

    trait :item do
      kind { "item" }
      amount { 1 }
      entity_class { Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "entity-class") }
      entity_name { "MG Scrip" }
      org_key { nil }
      org_name { nil }
    end

    trait :badge do
      kind { "badge" }
      amount { nil }
      badge { "WelcomeToPyro_Firesale" }
      org_key { nil }
      org_name { nil }
    end

    # 16 of the 58 amounts the export declares are negative: work for one side
    # costs you standing with the other.
    trait :penalty do
      amount { -1_000 }
    end
  end
end

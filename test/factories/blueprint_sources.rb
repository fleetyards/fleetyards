# frozen_string_literal: true

# == Schema Information
#
# Table name: blueprint_sources
#
#  id                 :uuid             not null, primary key
#  kind               :string           not null
#  max_standing       :string
#  min_points         :integer
#  min_standing       :string
#  mission_name       :string
#  org_name           :string
#  org_ref            :string
#  pool_group         :string
#  pool_key           :string
#  pool_sc_ref        :string           not null
#  position           :integer          not null
#  source_key         :string
#  weight             :decimal(8, 3)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  blueprint_build_id :uuid             not null
#
# Indexes
#
#  index_blueprint_sources_on_build               (blueprint_build_id)
#  index_blueprint_sources_on_build_and_position  (blueprint_build_id,position) UNIQUE
#  index_blueprint_sources_on_org_name            (org_name)
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_build_id => blueprint_builds.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :blueprint_source do
    build factory: :blueprint_build
    kind { "contract" }
    sequence(:pool_sc_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "pool-#{n}") }
    pool_key { "bp_missionreward_example" }
    pool_group { "blueprintmissionpools" }
    weight { 1 }
    org_name { "Foxwell Enforcement" }
    sequence(:org_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "org-#{n}") }
    source_key { "foxwellenforcement_ambush" }
    mission_name { "Yellow Level Contract: Ambush An Amateur" }
    min_standing { "Neutral" }
    max_standing { "Elite Contractor" }
    sequence(:position) { |n| n }

    # XenoThreat hands its pools out by scenario progress rather than by
    # contract, so there is no mission and no standing band -- a points
    # threshold instead.
    trait :scenario do
      kind { "scenario" }
      pool_group { "xenothreat2rewards" }
      source_key { "rox_scenarioprogress" }
      mission_name { nil }
      min_standing { nil }
      max_standing { nil }
      min_points { 18_000 }
    end

    # A generator naming more than one faction: the org is left blank rather
    # than guessed.
    trait :unattributed do
      org_name { nil }
      org_ref { nil }
    end
  end
end

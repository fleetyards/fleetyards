# frozen_string_literal: true

# == Schema Information
#
# Table name: game_mission_builds
#
#  id                          :uuid             not null, primary key
#  alignment                   :string
#  blueprint_pool_refs         :text             default([]), not null, is an Array
#  debug_name                  :string
#  description                 :text
#  difficulty_game_knowledge   :integer
#  difficulty_mechanical_skill :integer
#  difficulty_mental_load      :integer
#  difficulty_profile          :string
#  difficulty_risk_of_loss     :integer
#  environment                 :string           not null
#  generator_key               :string
#  kind                        :string
#  max_standing                :string
#  min_standing                :string
#  name                        :string
#  org_key                     :string
#  org_lawful                  :boolean
#  org_name                    :string
#  org_ref                     :string
#  released                    :boolean          default(TRUE), not null
#  reward_kinds                :text             default([]), not null, is an Array
#  version                     :string           not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  game_mission_id             :uuid             not null
#
# Indexes
#
#  index_game_mission_builds_on_blueprint_pool_refs       (blueprint_pool_refs) USING gin
#  index_game_mission_builds_on_environment_and_name      (environment,name)
#  index_game_mission_builds_on_environment_and_org_name  (environment,org_name)
#  index_game_mission_builds_on_environment_and_version   (environment,version)
#  index_game_mission_builds_on_game_mission_id           (game_mission_id)
#  index_game_mission_builds_on_mission_and_build         (game_mission_id,environment,version) UNIQUE
#  index_game_mission_builds_on_reward_kinds              (reward_kinds) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (game_mission_id => game_missions.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :game_mission_build do
    game_mission factory: [:game_mission, :without_build]
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    sequence(:name) { |n| "Yellow Level Contract: Ambush An Amateur #{n}" }
    kind { "career" }
    org_name { "Foxwell Enforcement" }
    alignment { "lawful" }
    min_standing { "Neutral" }
    max_standing { "Elite Contractor" }
    released { true }
    reward_kinds { ["reputation"] }
  end
end

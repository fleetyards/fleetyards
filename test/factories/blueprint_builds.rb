# frozen_string_literal: true

# == Schema Information
#
# Table name: blueprint_builds
#
#  id             :uuid             not null, primary key
#  category_ref   :string
#  craft_time     :integer
#  craftable_type :string
#  environment    :string           not null
#  name           :string
#  slot_count     :integer
#  version        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  blueprint_id   :uuid             not null
#  craftable_id   :uuid
#
# Indexes
#
#  index_blueprint_builds_on_blueprint_and_build      (blueprint_id,environment,version) UNIQUE
#  index_blueprint_builds_on_blueprint_id             (blueprint_id)
#  index_blueprint_builds_on_environment_and_name     (environment,name)
#  index_blueprint_builds_on_environment_and_version  (environment,version)
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_id => blueprints.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :blueprint_build do
    blueprint
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    sequence(:name) { |n| "Crafted Item #{n}" }
    craft_time { 120 }
    slot_count { 3 }
  end
end

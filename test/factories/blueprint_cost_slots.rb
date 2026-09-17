# frozen_string_literal: true

# == Schema Information
#
# Table name: blueprint_cost_slots
#
#  id                 :uuid             not null, primary key
#  name               :string
#  position           :integer          not null
#  sc_key             :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  blueprint_build_id :uuid             not null
#
# Indexes
#
#  index_blueprint_cost_slots_on_build               (blueprint_build_id)
#  index_blueprint_cost_slots_on_build_and_position  (blueprint_build_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_build_id => blueprint_builds.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :blueprint_cost_slot do
    build factory: :blueprint_build
    sequence(:position) { |n| n }
    sc_key { "frame" }
    name { "Frame" }

    trait :with_option do
      after(:create) do |slot|
        create(:blueprint_cost_option, slot:)
      end
    end
  end
end

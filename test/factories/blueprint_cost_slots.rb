# frozen_string_literal: true

# == Schema Information
#
# Table name: blueprint_cost_slots
#
#  id           :uuid             not null, primary key
#  name         :string
#  position     :integer          not null
#  sc_key       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  blueprint_id :uuid             not null
#
# Indexes
#
#  index_blueprint_cost_slots_on_blueprint_id               (blueprint_id)
#  index_blueprint_cost_slots_on_blueprint_id_and_position  (blueprint_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_id => blueprints.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :blueprint_cost_slot do
    blueprint
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

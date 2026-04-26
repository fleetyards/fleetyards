# frozen_string_literal: true

# == Schema Information
#
# Table name: model_positions
#
#  id            :uuid             not null, primary key
#  name          :string           not null
#  position      :integer          default(0), not null
#  position_type :integer          not null
#  source        :integer          default("sc_data"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hardpoint_id  :uuid
#  model_id      :uuid             not null
#
# Indexes
#
#  index_model_positions_on_model_id                   (model_id)
#  index_model_positions_on_model_id_and_hardpoint_id  (model_id,hardpoint_id) UNIQUE WHERE (hardpoint_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (hardpoint_id => hardpoints.id)
#  fk_rails_...  (model_id => models.id)
#
FactoryBot.define do
  factory :model_position do
    model
    name { "Pilot" }
    position_type { :pilot }
    source { :sc_data }
    position { 0 }

    trait :copilot do
      name { "Copilot" }
      position_type { :copilot }
      position { 1 }
    end

    trait :turret_gunner do
      name { "Turret Gunner" }
      position_type { :turret_gunner }
      position { 2 }
    end

    trait :engineer do
      name { "Engineer" }
      position_type { :engineer }
      position { 3 }
    end

    trait :loadmaster do
      name { "Loadmaster" }
      position_type { :loadmaster }
      position { 4 }
    end

    trait :curated do
      source { :curated }
    end

    trait :passenger do
      name { "Passenger" }
      position_type { :passenger }
      source { :curated }
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_loadouts
#
#  id         :uuid             not null, primary key
#  active     :boolean          default(FALSE), not null
#  name       :string           not null
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vehicle_id :uuid             not null
#
# Indexes
#
#  index_vehicle_loadouts_on_vehicle_id           (vehicle_id)
#  index_vehicle_loadouts_on_vehicle_id_and_name  (vehicle_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id)
#
FactoryBot.define do
  factory :vehicle_loadout do
    name { Faker::Lorem.word }
    url { "https://erkul.games/loadout/#{SecureRandom.hex(8)}" }
    vehicle

    trait :active do
      active { true }
    end
  end
end

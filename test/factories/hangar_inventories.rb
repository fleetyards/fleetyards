# frozen_string_literal: true

# == Schema Information
#
# Table name: hangar_inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null
#
# Indexes
#
#  index_hangar_inventories_on_user_id_and_lower_name  (user_id, lower((name)::text)) UNIQUE
#  index_hangar_inventories_on_user_id_and_slug        (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :hangar_inventory do
    user
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 2)} #{n}" }
    description { Faker::Lorem.sentence }

    trait :with_location do
      location { Faker::Space.planet }
    end
  end
end

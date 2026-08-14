# frozen_string_literal: true

# == Schema Information
#
# Table name: inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  holder_type :string           not null
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  holder_id   :uuid             not null
#
# Indexes
#
#  index_inventories_on_holder_and_lower_name               (holder_type, holder_id, lower((name)::text)) UNIQUE
#  index_inventories_on_holder_type_and_holder_id           (holder_type,holder_id)
#  index_inventories_on_holder_type_and_holder_id_and_slug  (holder_type,holder_id,slug) UNIQUE
#
FactoryBot.define do
  factory :inventory do
    association :holder, factory: :user
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 2)} #{n}" }
    description { Faker::Lorem.sentence }

    trait :with_location do
      location { Faker::Space.planet }
    end
  end
end

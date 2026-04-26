# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  location    :string
#  managed_by  :uuid
#  name        :string           not null
#  slug        :string           not null
#  visibility  :integer          default("members_only"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  fleet_id    :uuid             not null
#
# Indexes
#
#  index_fleet_inventories_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
#  index_fleet_inventories_on_fleet_id_and_managed_by  (fleet_id,managed_by)
#  index_fleet_inventories_on_fleet_id_and_slug        (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (managed_by => users.id)
#
FactoryBot.define do
  factory :fleet_inventory do
    fleet
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 2)} #{n}" }
    description { Faker::Lorem.sentence }
    visibility { :members_only }

    trait :officers_only do
      visibility { :officers_only }
    end

    trait :with_manager do
      association :manager, factory: :user
    end
  end
end

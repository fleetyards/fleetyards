# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadrons
#
#  id                :uuid             not null, primary key
#  color             :string
#  description       :text
#  name              :string           not null
#  position          :integer          default(0), not null
#  short_description :text
#  slug              :string           not null
#  team              :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid             not null
#
# Indexes
#
#  index_fleet_squadrons_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
#  index_fleet_squadrons_on_fleet_id_and_position    (fleet_id,position)
#  index_fleet_squadrons_on_fleet_id_and_slug        (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
FactoryBot.define do
  factory :fleet_squadron do
    fleet
    sequence(:name) { |n| "#{Faker::Military.air_force_rank} Wing #{n}" }
    short_description { Faker::Lorem.sentence }

    trait :with_color do
      color { "#ff8800" }
    end

    trait :with_icon do
      icon { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_header do
      header { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg") }
    end
  end
end

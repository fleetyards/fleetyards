# == Schema Information
#
# Table name: images
#
#  id           :uuid             not null, primary key
#  background   :boolean          default(TRUE)
#  caption      :string
#  enabled      :boolean          default(FALSE), not null
#  gallery_name :string
#  gallery_slug :string
#  gallery_type :string(255)
#  global       :boolean          default(TRUE)
#  created_at   :datetime
#  updated_at   :datetime
#  gallery_id   :uuid
#
# Indexes
#
#  index_images_on_gallery_id  (gallery_id)
#
FactoryBot.define do
  factory :image do
    file { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/image.jpg"), "image/jpeg") }
    gallery { create(:model) }
    enabled { true }
    global { true }

    trait :disabled do
      enabled { false }
    end

    trait :private do
      global { false }
    end

    trait :no_background do
      background { false }
    end
  end
end

# == Schema Information
#
# Table name: model_paints
#
#  id                      :uuid             not null, primary key
#  active                  :boolean          default(TRUE)
#  description             :string
#  hidden                  :boolean          default(TRUE)
#  last_updated_at         :datetime
#  name                    :string
#  on_sale                 :boolean          default(FALSE)
#  pledge_price            :decimal(15, 2)
#  production_note         :string
#  production_status       :string
#  rsi_description         :string
#  rsi_name                :string
#  rsi_slug                :string
#  rsi_store_url           :string
#  slug                    :string
#  store_images_updated_at :datetime
#  store_url               :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid
#  rsi_id                  :integer
#
FactoryBot.define do
  factory :model_paint do
    name { Faker::Name.name }
    model
    hidden { false }
    active { true }

    trait :hidden do
      hidden { true }
    end

    trait :on_sale do
      on_sale { true }
      pledge_price { 10.0 }
    end

    trait :with_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/ship.jpg"), "image/jpeg") }
    end

    trait :with_fleetchart_image do
      fleetchart_image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test.png"), "image/png") }
    end

    trait :with_rsi_data do
      rsi_id { Faker::Number.number(digits: 5) }
      rsi_name { name }
      rsi_slug { name.parameterize }
    end
  end
end

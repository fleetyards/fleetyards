# == Schema Information
#
# Table name: manufacturers
#
#  id           :uuid             not null, primary key
#  code         :string
#  code_mapping :string
#  description  :text
#  known_for    :string(255)
#  logo         :string(255)
#  long_name    :string
#  name         :string(255)
#  sc_ref       :string
#  slug         :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  rsi_id       :integer
#
FactoryBot.define do
  factory :manufacturer do
    name { Faker::Name.name }
    code { Faker::Name.initials(number: 4) }
    logo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    long_name { name }
    sc_ref { name.parameterize }

    trait :with_models do
      transient do
        models_count { 5 }
      end

      after(:create) do |manufacturer, evaluator|
        create_list(:model, evaluator.models_count, manufacturer: manufacturer)
      end
    end
  end
end

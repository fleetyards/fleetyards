FactoryBot.define do
  factory :hangar_group do
    name { Faker::Alphanumeric.alphanumeric(number: 10) }
    color { Faker::Color.hex_color }
    public { false }

    association :user

    trait :with_vehicles do
      after(:create) do |hangar_group|
        create_list(:vehicle, 3, hangar_group: hangar_group)
      end
    end

    trait :public do
      public { true }
    end
  end
end

FactoryBot.define do
  factory :vehicle do
    model
    user

    wanted { false }
    loaner { false }

    trait :with_name do
      name { Faker::Name.name }
      name_visible { true }
    end

    trait :wanted do
      wanted { true }
    end

    trait :loaner do
      loaner { true }
    end

    trait :bundled do
      bundled { true }
    end

    trait :flagship do
      flagship { true }
    end

    trait :hidden do
      hidden { true }
    end

    trait :public do
      public { true }
    end

    trait :bought_ingame do
      bought_via { :ingame }
    end

    trait :with_serial do
      serial { SecureRandom.hex(8) }
    end

    trait :with_paint do
      model_paint { association :model_paint, model: model }
    end
  end
end

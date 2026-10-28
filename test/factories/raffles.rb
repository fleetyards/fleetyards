# frozen_string_literal: true

FactoryBot.define do
  factory :raffle do
    sequence(:title) { |n| "Raffle ##{n}" }
    prize { "Anvil Polaris game package" }
    code { "GIFT-#{SecureRandom.hex(6).upcase}" }
    starts_at { 1.day.ago }
    run_days { 7 }
    published { true }

    # Publishing needs a picture; one shared blob keeps the factory cheap.
    images do
      [ActiveStorage::Blob.find_by(filename: "raffle-factory.png") ||
        ActiveStorage::Blob.create_and_upload!(
          io: File.open(Rails.root.join("test/fixtures/files/test.png")),
          filename: "raffle-factory.png", content_type: "image/png"
        )]
    end

    trait :draft do
      published { false }
    end

    trait :upcoming do
      starts_at { 2.days.from_now }
    end

    trait :closed do
      starts_at { 10.days.ago }
      run_days { 9 }
    end
  end

  factory :raffle_entry do
    raffle
    user
    conditions_accepted { true }

    # Entries can only be created while a raffle is open; a closed raffle in a
    # test gets its entries first and its dates moved after.
    trait :after_close do
      to_create do |entry|
        entry.save!(validate: false)
      end
      conditions_accepted_at { Time.current }
      conditions_version { Raffle::CONDITIONS_VERSION }
      email { user&.email }
    end
  end
end

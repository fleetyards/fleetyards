# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_transfer_rule do
    user
    association :subject_user, factory: :user
    effect { :deny }

    trait :allow do
      effect { :allow }
    end

    trait :held_by_fleet do
      user { nil }
      fleet
    end

    trait :about_fleet do
      subject_user { nil }
      association :subject_fleet, factory: :fleet
    end
  end
end

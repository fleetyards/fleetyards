# frozen_string_literal: true

FactoryBot.define do
  factory :user_blueprint do
    user
    blueprint

    trait :wanted do
      wanted { true }
    end
  end
end

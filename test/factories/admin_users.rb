FactoryBot.define do
  factory :admin_user do
    sequence(:username) { |n| "#{Faker::Internet.username(separators: ["_"])}_#{n}" }
    sequence(:email) { |n| Faker::Internet.email(name: "admin#{n}") }
    password { Faker::Internet.password }
    password_confirmation { password }

    trait :super_admin do
      super_admin { true }
    end
  end
end

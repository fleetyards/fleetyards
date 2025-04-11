FactoryBot.define do
  factory :admin_user do
    username { Faker::Internet.username(separators: ["_"]) }
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    password_confirmation { password }
  end
end

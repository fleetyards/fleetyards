FactoryBot.define do
  factory :video do
    model
    url { Faker::Internet.url }
    video_type { Video.video_types.keys.sample }
  end
end

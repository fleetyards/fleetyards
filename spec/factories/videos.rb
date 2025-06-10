# == Schema Information
#
# Table name: videos
#
#  id         :uuid             not null, primary key
#  url        :string
#  video_type :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  model_id   :uuid
#
# Indexes
#
#  index_videos_on_model_id  (model_id)
#
FactoryBot.define do
  factory :video do
    url { Faker::Internet.url }
    video_type { Video.video_types.keys.sample }
  end
end

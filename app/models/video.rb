# frozen_string_literal: true

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
class Video < ApplicationRecord
  paginates_per 8

  belongs_to :model, optional: false, counter_cache: true

  enum video_type: { youtube: 0 }

  validates :url, :video_type, presence: true

  def video_url
    return url unless youtube?

    "https://www.youtube-nocookie.com/embed/#{url}"
  end

  def video_id
    return unless youtube?

    url
  end
end

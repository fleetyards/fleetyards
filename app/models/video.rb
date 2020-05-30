# frozen_string_literal: true

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

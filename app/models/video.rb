# frozen_string_literal: true

class Video < ApplicationRecord
  paginates_per 8

  belongs_to :model, touch: true, counter_cache: true

  enum :video_type,
    {youtube: 0}

  validates :url, :video_type, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[id url video_type model_id created_at updated_at]
  end

  def video_url
    return url unless youtube?

    "https://www.youtube-nocookie.com/embed/#{url}"
  end

  def video_id
    return unless youtube?

    url
  end
end

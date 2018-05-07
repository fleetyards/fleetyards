# frozen_string_literal: true

class Video < ApplicationRecord
  belongs_to :model, required: true

  enum video_type: %i[youtube]

  validates :url, :video_type, presence: true

  def video_url
    return url unless youtube?

    "https://www.youtube.com/embed/#{url}?loop=1&playlist=#{url}"
  end
end

# frozen_string_literal: true

class Video < ApplicationRecord
  belongs_to :model, required: true

  enum video_type: %i[youtube]

  validates :url, :video_type, presence: true
end

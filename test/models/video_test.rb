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
require 'test_helper'

class VideoTest < ActiveSupport::TestCase
  should belong_to(:model)
  should define_enum_for(:video_type).with_values([:youtube])

  should validate_presence_of(:url)
  should validate_presence_of(:video_type)
end

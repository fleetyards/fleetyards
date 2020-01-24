# frozen_string_literal: true

require 'test_helper'

class VideoTest < ActiveSupport::TestCase
  should belong_to(:model)
  should define_enum_for(:video_type).with_values([:youtube])

  should validate_presence_of(:url)
  should validate_presence_of(:video_type)
end

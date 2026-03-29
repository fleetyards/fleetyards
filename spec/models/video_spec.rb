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
require "rails_helper"

RSpec.describe Video, type: :model do
  it { is_expected.to belong_to(:model) }
  it { is_expected.to define_enum_for(:video_type).with_values([:youtube]) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:video_type) }
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Video, type: :model do
  it { is_expected.to belong_to(:model) }
  it { is_expected.to define_enum_for(:video_type).with_values([:youtube]) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:video_type) }
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id               :uuid             not null, primary key
#  background_image :string
#  created_by       :uuid
#  description      :text
#  discord          :string
#  fid              :string
#  guilded          :string
#  homepage         :string
#  logo             :string
#  name             :string
#  public_fleet     :boolean          default(FALSE)
#  rsi_sid          :string
#  sid              :string
#  slug             :string
#  ts               :string
#  twitch           :string
#  youtube          :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_fleets_on_fid  (fid) UNIQUE
#
require 'test_helper'

class FleetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

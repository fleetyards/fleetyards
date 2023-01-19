# frozen_string_literal: true

# == Schema Information
#
# Table name: starsystems
#
#  id                    :uuid             not null, primary key
#  aggregated_danger     :integer
#  aggregated_economy    :integer
#  aggregated_population :integer
#  aggregated_size       :string
#  code                  :string
#  description           :text
#  hidden                :boolean          default(TRUE)
#  last_updated_at       :datetime
#  map                   :string
#  map_x                 :string
#  map_y                 :string
#  name                  :string
#  position_x            :string
#  position_y            :string
#  position_z            :string
#  slug                  :string
#  status                :string
#  store_image           :string
#  system_type           :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  rsi_id                :integer
#
# Indexes
#
#  starsystems_slug_index  (slug) UNIQUE
#
require 'test_helper'

class StarsystemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

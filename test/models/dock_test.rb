# frozen_string_literal: true

# == Schema Information
#
# Table name: docks
#
#  id            :uuid             not null, primary key
#  beam          :decimal(15, 2)
#  dock_type     :integer
#  group         :string
#  height        :decimal(15, 2)
#  length        :decimal(15, 2)
#  max_ship_size :integer
#  min_ship_size :integer
#  name          :string
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid
#  station_id    :uuid
#
# Indexes
#
#  index_docks_on_station_id  (station_id)
#
require 'test_helper'

class DockTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

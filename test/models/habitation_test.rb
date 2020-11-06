# frozen_string_literal: true

# == Schema Information
#
# Table name: habitations
#
#  id              :uuid             not null, primary key
#  habitation_name :string
#  habitation_type :integer
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  station_id      :uuid
#
# Indexes
#
#  index_habitations_on_station_id  (station_id)
#
require 'test_helper'

class HabitationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

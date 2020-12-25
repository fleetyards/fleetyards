# frozen_string_literal: true

# == Schema Information
#
# Table name: progress_tracker_items
#
#  id                :uuid             not null, primary key
#  description       :string
#  discipline_counts :integer
#  end_date          :date
#  key               :string
#  projects          :string
#  start_date        :date
#  team              :string
#  time_allocations  :string
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  model_id          :uuid
#
# Indexes
#
#  index_progress_tracker_items_on_key  (key) UNIQUE
#
require 'test_helper'

class ProgressTrackerItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

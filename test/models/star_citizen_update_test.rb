# frozen_string_literal: true

# == Schema Information
#
# Table name: star_citizen_updates
#
#  id            :uuid             not null, primary key
#  news_sub_type :string
#  news_type     :string
#  slug          :string
#  title         :string
#  url           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'test_helper'

class StarCitizenUpdateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

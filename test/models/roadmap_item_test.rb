# frozen_string_literal: true

# == Schema Information
#
# Table name: roadmap_items
#
#  id                  :uuid             not null, primary key
#  active              :boolean
#  body                :text
#  completed           :integer
#  description         :text
#  image               :string
#  inprogress          :integer
#  name                :string
#  release             :string
#  release_description :text
#  released            :boolean
#  store_image         :string
#  tasks               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  model_id            :uuid
#  rsi_category_id     :integer
#  rsi_id              :integer
#  rsi_release_id      :integer
#
require 'test_helper'

class RoadmapItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

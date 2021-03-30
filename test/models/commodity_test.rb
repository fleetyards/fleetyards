# frozen_string_literal: true

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :integer
#  description    :text
#  name           :string
#  slug           :string
#  store_image    :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_commodities_on_name  (name) UNIQUE
#
require 'test_helper'

class CommodityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

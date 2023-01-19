# frozen_string_literal: true

# == Schema Information
#
# Table name: shops
#
#  id                :uuid             not null, primary key
#  buying            :boolean          default(FALSE)
#  description       :text
#  hidden            :boolean          default(TRUE)
#  location          :string
#  name              :string
#  refinery_terminal :boolean
#  rental            :boolean          default(FALSE)
#  selling           :boolean          default(FALSE)
#  shop_type         :integer
#  slug              :string
#  store_image       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  station_id        :uuid
#
# Indexes
#
#  index_shops_on_station_id  (station_id)
#  shops_station_id_index     (station_id)
#
require "test_helper"

class ShopTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

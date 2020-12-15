# frozen_string_literal: true

# == Schema Information
#
# Table name: stations
#
#  id                  :uuid             not null, primary key
#  cargo_hub           :boolean
#  classification      :integer
#  description         :text
#  habitable           :boolean          default(TRUE)
#  hidden              :boolean          default(TRUE)
#  images_count        :integer          default(0)
#  location            :string
#  map                 :string
#  name                :string
#  refinary            :boolean
#  slug                :string
#  station_type        :integer
#  status              :integer
#  store_image         :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  celestial_object_id :uuid
#  planet_id           :uuid
#
# Indexes
#
#  index_stations_on_celestial_object_id  (celestial_object_id)
#  index_stations_on_name                 (name) UNIQUE
#  index_stations_on_planet_id            (planet_id)
#
require 'test_helper'

class StationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

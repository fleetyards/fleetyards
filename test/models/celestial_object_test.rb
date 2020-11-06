# frozen_string_literal: true

# == Schema Information
#
# Table name: celestial_objects
#
#  id                :uuid             not null, primary key
#  code              :string
#  description       :text
#  designation       :string
#  fairchanceact     :boolean
#  habitable         :boolean
#  hidden            :boolean          default(TRUE)
#  last_updated_at   :datetime
#  name              :string
#  object_type       :string
#  orbit_period      :string
#  sensor_danger     :integer
#  sensor_economy    :integer
#  sensor_population :integer
#  size              :string
#  slug              :string
#  status            :string
#  store_image       :string
#  sub_type          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :uuid
#  rsi_id            :integer
#  starsystem_id     :uuid
#
# Indexes
#
#  index_celestial_objects_on_starsystem_id  (starsystem_id)
#
require 'test_helper'

class CelestialObjectTest < ActiveSupport::TestCase
  should belong_to(:starsystem).optional(true)
  should belong_to(:parent).optional(true)
end

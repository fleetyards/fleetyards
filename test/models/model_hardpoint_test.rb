# frozen_string_literal: true

# == Schema Information
#
# Table name: model_hardpoints
#
#  id                 :uuid             not null, primary key
#  category           :integer
#  deleted_at         :datetime
#  details            :string
#  group              :integer
#  hardpoint_type     :integer
#  item_slot          :integer
#  item_slots         :integer
#  key                :string
#  loadout_identifier :string
#  mount              :string
#  name               :string
#  size               :integer
#  source             :integer
#  sub_category       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  component_id       :uuid
#  model_id           :uuid
#
# Indexes
#
#  index_model_hardpoints_on_component_id  (component_id)
#  index_model_hardpoints_on_model_id      (model_id)
#
require "test_helper"

class ModelHardpointTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

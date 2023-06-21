# == Schema Information
#
# Table name: model_snub_crafts
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid             not null
#  snub_craft_id :uuid             not null
#
require "test_helper"

class ModelSnubCraftTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

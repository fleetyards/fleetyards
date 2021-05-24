# == Schema Information
#
# Table name: model_hardpoint_loadouts
#
#  id                 :uuid             not null, primary key
#  name               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  component_id       :uuid
#  model_hardpoint_id :uuid
#
require "test_helper"

class ModelHardpointLoadoutTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

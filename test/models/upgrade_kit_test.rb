# frozen_string_literal: true

# == Schema Information
#
# Table name: upgrade_kits
#
#  id               :uuid             not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  model_id         :uuid
#  model_upgrade_id :uuid
#
require 'test_helper'

class UpgradeKitTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

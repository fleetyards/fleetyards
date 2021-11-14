# frozen_string_literal: true

# == Schema Information
#
# Table name: model_module_package_items
#
#  id                      :uuid             not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_module_id         :uuid
#  model_module_package_id :uuid
#
require 'test_helper'

class ModelModulePackageItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

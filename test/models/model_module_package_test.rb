# frozen_string_literal: true

# == Schema Information
#
# Table name: model_module_packages
#
#  id           :uuid             not null, primary key
#  active       :boolean          default(TRUE)
#  description  :text
#  hidden       :boolean          default(TRUE)
#  name         :string
#  pledge_price :decimal(15, 2)
#  slug         :string
#  store_image  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  model_id     :uuid
#
require 'test_helper'

class ModelModulePackageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

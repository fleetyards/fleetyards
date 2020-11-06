# frozen_string_literal: true

# == Schema Information
#
# Table name: model_upgrades
#
#  id           :uuid             not null, primary key
#  active       :boolean          default(FALSE)
#  description  :text
#  hidden       :boolean          default(TRUE)
#  name         :string
#  pledge_price :decimal(15, 2)
#  slug         :string
#  store_image  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'test_helper'

class ModelUpgradeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

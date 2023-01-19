# frozen_string_literal: true

# == Schema Information
#
# Table name: model_module_packages
#
#  id                 :uuid             not null, primary key
#  active             :boolean          default(TRUE)
#  angled_view        :string
#  angled_view_height :integer
#  angled_view_width  :integer
#  description        :text
#  hidden             :boolean          default(TRUE)
#  name               :string
#  pledge_price       :decimal(15, 2)
#  side_view          :string
#  side_view_height   :integer
#  side_view_width    :integer
#  slug               :string
#  store_image        :string
#  top_view           :string
#  top_view_height    :integer
#  top_view_width     :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  model_id           :uuid
#
require "test_helper"

class ModelModulePackageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

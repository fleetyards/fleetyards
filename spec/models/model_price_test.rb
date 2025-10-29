# == Schema Information
#
# Table name: model_prices
#
#  id           :uuid             not null, primary key
#  location     :string
#  location_url :string
#  price        :decimal(15, 2)
#  price_type   :integer
#  time_range   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  model_id     :uuid             not null
#
# Indexes
#
#  index_model_prices_on_model_id  (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id)
#
require "test_helper"

class ModelPriceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

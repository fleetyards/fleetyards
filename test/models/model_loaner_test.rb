# frozen_string_literal: true

# == Schema Information
#
# Table name: model_loaners
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  loaner_model_id :uuid
#  model_id        :uuid
#
require 'test_helper'

class ModelLoanerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

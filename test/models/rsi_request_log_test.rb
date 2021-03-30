# frozen_string_literal: true

# == Schema Information
#
# Table name: rsi_request_logs
#
#  id         :uuid             not null, primary key
#  resolved   :boolean
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class RsiRequestLogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

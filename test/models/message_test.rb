# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id         :uuid             not null, primary key
#  archived   :boolean          default(FALSE)
#  body       :text
#  email      :string
#  from       :string
#  from_raw   :text
#  read       :boolean          default(FALSE)
#  subject    :string
#  to         :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

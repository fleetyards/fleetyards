# frozen_string_literal: true

# == Schema Information
#
# Table name: message_attachments
#
#  id         :uuid             not null, primary key
#  payload    :binary
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  message_id :uuid
#
require "test_helper"

class MessageAttachmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

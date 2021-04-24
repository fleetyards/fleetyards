# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_channels
#
#  id                :uuid             not null, primary key
#  channel           :string
#  confirmed         :boolean          default(FALSE)
#  unsubscribe_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid
#
# Indexes
#
#  index_notification_channels_on_user_id_and_channel  (user_id,channel) UNIQUE
#
require 'test_helper'

class NotificationChannelTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

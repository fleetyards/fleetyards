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
class MessageAttachment < ApplicationRecord
  belongs_to :message
end

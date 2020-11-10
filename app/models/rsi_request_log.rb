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
class RsiRequestLog < ApplicationRecord
  after_create :notify_admin
  after_save :notify_admin_resolved

  def notify_admin
    AdminMailer.notify_block(url).deliver_later
  end

  def notify_admin_resolved
    return unless resolved

    AdminMailer.notify_unblock(url).deliver_later
  end
end

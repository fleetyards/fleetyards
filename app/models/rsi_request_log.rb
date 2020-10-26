# frozen_string_literal: true

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

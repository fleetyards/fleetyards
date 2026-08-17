# frozen_string_literal: true

# == Schema Information
#
# Table name: rsi_request_logs
#
#  id         :uuid             not null, primary key
#  resolved   :boolean          default(FALSE)
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class RsiRequestLog < ApplicationRecord
  after_create :notify_admin
  after_save :notify_admin_resolved

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at resolved url]
  end

  def notify_admin
    AdminMailer.notify_block(url).deliver_later

    AdminNotification.notify!(
      type: :rsi_api_blocked,
      title: "RSI blocked a request",
      body: url,
      severity: :error,
      link: "/maintenance/rsi-api-status",
      record: self,
      dedupe_key: url
    )
  end

  def notify_admin_resolved
    return unless resolved

    AdminMailer.notify_unblock(url).deliver_later

    AdminNotification.notify!(
      type: :rsi_api_unblocked,
      title: "RSI unblocked a request",
      body: url,
      link: "/maintenance/rsi-api-status",
      record: self,
      dedupe_key: url
    )
  end
end

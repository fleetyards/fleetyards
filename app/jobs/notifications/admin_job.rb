# frozen_string_literal: true

module Notifications
  class AdminJob < ::Notifications::BaseJob
    def perform
      report = AdminWeeklyReport.build

      # Delivered inline: the report carries Struct values that ActiveJob cannot
      # serialize, and this job is already running in the background.
      AdminUser.where(super_admin: true).find_each do |admin_user|
        AdminMailer.weekly(admin_user, report).deliver_now
      end

      AdminNotification.notify!(
        type: :weekly_stats,
        title: I18n.t(:"mailer.admin.weekly.headline"),
        body: notification_body(report),
        link: "/"
      )
    end

    private def notification_body(report)
      report[:sections].flat_map do |section|
        [
          "## #{I18n.t(:"mailer.admin.weekly.sections.#{section.key}")}",
          "",
          *section.metrics.map { |metric| metric_line(metric) },
          ""
        ]
      end.join("\n").strip
    end

    private def metric_line(metric)
      label = I18n.t(:"mailer.admin.weekly.metrics.#{metric.key}")
      value = (metric.format == :currency) ? format("%.2f EUR", metric.current.to_f / 100) : metric.current

      return "- #{label}: #{value}" unless metric.comparable?

      "- #{label}: #{value} (#{"+" unless metric.delta.negative?}#{metric.delta})"
    end
  end
end

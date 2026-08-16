# frozen_string_literal: true

module AdminReportHelper
  def admin_report_metric_value(metric)
    admin_report_format_value(metric.current, metric.format)
  end

  def admin_report_previous_value(metric)
    return unless metric.comparable?

    admin_report_format_value(metric.previous, metric.format)
  end

  def admin_report_delta(metric)
    delta = metric.delta
    return if delta.nil? || delta.zero?

    "#{delta.positive? ? "+" : "-"}#{admin_report_format_value(delta.abs, metric.format)}"
  end

  # Growth is not universally good — more failed imports or lost supporters are
  # the same arrow pointing the wrong way, so the metric decides its own polarity.
  def admin_report_delta_class(metric)
    delta = metric.delta
    return "neutral" if delta.nil? || delta.zero?

    improving = AdminWeeklyReport::LOWER_IS_BETTER.include?(metric.key) ? delta.negative? : delta.positive?

    improving ? "positive" : "negative"
  end

  private def admin_report_format_value(value, format)
    case format
    when :currency then Kernel.format("%.2f EUR", value.to_f / 100)
    else number_with_delimiter(value)
    end
  end
end

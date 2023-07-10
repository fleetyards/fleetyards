# frozen_string_literal: true

module ChartHelper
  def transform_for_pie_chart(data)
    data.sort_by { |_label, count| count }.reverse
      .each_with_index.map do |(label, count), index|
      point = {
        name: label,
        y: count
      }
      if index.zero?
        point[:selected] = true
        point[:sliced] = true
      else
        point[:selected] = false
        point[:sliced] = false
      end
      point
    end
  end

  def transform_for_bar_chart(data)
    data.sort_by { |_label, count| count }.reverse.each.map do |label, count|
      {
        label:,
        count:,
        tooltip: label
      }
    end
  end
end

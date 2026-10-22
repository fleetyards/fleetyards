# frozen_string_literal: true

metrics.each do |key, value|
  if value.is_a?(Array)
    json.set! key, value.map { |count| {name: count.name, count: count.count} }
  else
    json.set! key, value.is_a?(BigDecimal) ? value.to_f : value
  end
end

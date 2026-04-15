# frozen_string_literal: true

json.model_counts do
  json.key_format! ->(key) { key }
  @model_counts.each do |slug, count|
    json.set! slug, count
  end
end

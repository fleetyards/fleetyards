json.total_count result.respond_to?(:total_count) ? result.total_count : result.count
json.current_page result.respond_to?(:current_page) ? result.current_page : 1
json.total_pages result.respond_to?(:total_pages) ? result.total_pages : 1
json.per_page result.limit_value
json.default_per_page result.default_per_page
json.max_per_page result.max_per_page
if result.per_page_steps.present?
  json.per_page_steps result.per_page_steps
end

json.total_count result.respond_to?(:total_count) ? result.total_count : result.count
json.current_page result.respond_to?(:current_page) ? result.current_page : 1
json.total_pages result.respond_to?(:total_pages) ? result.total_pages : 1
json.per_page result.limit_value
json.default_per_page result.default_per_page
json.max_per_page result.max_per_page
# A paginated array has no model to ask, so its caller passes the steps.
per_page_steps = local_assigns[:per_page_steps] || (result.per_page_steps if result.respond_to?(:per_page_steps))
json.per_page_steps per_page_steps if per_page_steps.present?

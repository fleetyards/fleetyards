# frozen_string_literal: true

json.meta do
  if result.respond_to?(:current_page)
    json.pagination do
      json.current_page result.current_page
      json.total_pages result.total_pages
      json.default_per_page result.default_per_page
      json.max_per_page result.max_per_page
      if result.per_page_steps.present?
        json.per_page_steps result.per_page_steps
      end
    end
  end
end

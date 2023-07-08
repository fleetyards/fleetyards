# frozen_string_literal: true

json.meta do
  if result.respond_to?(:current_page)
    json.pagination do
      json.current_page result.current_page
      json.total_pages result.total_pages
    end
  end
end

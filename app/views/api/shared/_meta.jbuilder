# frozen_string_literal: true

json.meta do
  json.pagination do
    json.total_count result.respond_to?(:total_count) ? result.total_count : 0
    json.current_page result.respond_to?(:current_page) ? result.current_page : 1
    json.total_pages result.respond_to?(:total_pages) ? result.total_pages : 1
    if result.instance_of?(Searchkick::Relation)
      first_result = result.first
      if first_result.present?
        json.default_per_page first_result.class.default_per_page
        json.max_per_page first_result.class.max_per_page
        if first_result.class.per_page_steps.present?
          json.per_page_steps first_result.class.per_page_steps
        end
      end
    else
      json.default_per_page result.default_per_page
      json.max_per_page result.max_per_page
      if result.per_page_steps.present?
        json.per_page_steps result.per_page_steps
      end
    end
  end
end

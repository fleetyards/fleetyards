# frozen_string_literal: true

json.meta do
  if result.respond_to?(:current_page)
    json.pagination do
      json.current_page result.current_page
      json.total_pages result.total_pages
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
end

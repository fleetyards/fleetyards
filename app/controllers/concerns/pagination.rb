# frozen_string_literal: true

module Pagination
  class MaxPerPageReached < StandardError; end

  def per_page(model)
    raise Pagination::MaxPerPageReached if params[:perPage].present? && params[:perPage].to_i > model.max_per_page

    return params[:perPage].to_i if params[:perPage].present?

    model.default_per_page
  end

  def pagination_header(name)
    scope = name
    scope = scope.find { |item| instance_variable_get("@#{item}") } if scope.is_a?(Array)

    headers['Link'] = pagination_links(instance_variable_get("@#{scope}")).filter_map do |k, v|
      next if v.blank?

      "<#{v}>; rel=\"#{k}\""
    end.join(', ')
  end

  private def pagination_links(scope)
    {
      first: (page_link(1) if scope.total_pages > 1 && !scope.first_page?),
      next: (page_link(scope.current_page + 1) unless scope.last_page?),
      prev: (page_link(scope.current_page - 1) unless scope.first_page?),
      last: (page_link(scope.total_pages) if scope.total_pages > 1 && !scope.last_page?)
    }
  end

  private def page_link(page)
    url_for(controller: controller_name, action: action_name, page: page)
  end
end

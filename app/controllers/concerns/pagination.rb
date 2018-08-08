# frozen_string_literal: true

module Concerns
  module Pagination
    def pagination_header(name)
      headers['Link'] = pagination_links(instance_variable_get("@#{name}")).map do |k, v|
        next if v.blank?
        "<#{v}>; rel=\"#{k}\""
      end.compact.join(', ')
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

    private def per_page
      @per_page ||= [params[:perPage].to_i, 200].min if params[:perPage].present?
    end
  end
end

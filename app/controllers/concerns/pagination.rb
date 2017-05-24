# encoding: utf-8
# frozen_string_literal: true

module Concerns
  module Pagination
    def pagination_header(name)
      headers["Link"] = pagination_links(name).map do |k, v|
        next if v.blank?
        "<#{v}>; rel=\"#{k}\""
      end.compact.join(", ")
    end

    private def pagination_links(name)
      scope = instance_variable_get("@#{name}")
      {
        first: (page_link(name, 1) if scope.total_pages > 1 && !scope.first_page?),
        next: (page_link(name, scope.current_page + 1) unless scope.last_page?),
        prev: (page_link(name, scope.current_page - 1) unless scope.first_page?),
        last: (page_link(name, scope.total_pages) if scope.total_pages > 1 && !scope.last_page?)
      }
    end

    private def page_link(name, page)
      url_for(controller: name, action: :index, page: page)
    end
  end
end

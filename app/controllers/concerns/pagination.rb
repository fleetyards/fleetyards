# frozen_string_literal: true

module Pagination
  class MaxPerPageReached < StandardError; end

  def per_page(model)
    return model.default_per_page if per_page_params.blank? || per_page_params.to_i.zero?

    raise Pagination::MaxPerPageReached if per_page_params.to_i > model.max_per_page

    per_page_params.to_i
  end

  def pagination_header(name)
    links = {
      self: page_link(nil)
    }

    scope = name
    scope = scope.find { |item| instance_variable_get("@#{item}") } if scope.is_a?(Array)

    if per_page_params != "all" && instance_variable_get("@#{scope}").present?
      links = links.merge(pagination_links(instance_variable_get("@#{scope}")))
    end

    headers["Link"] = links.filter_map do |k, v|
      next if v.blank?

      "<#{v}>; rel=\"#{k}\""
    end.join(", ")
  end

  private def result_with_pagination(result, per_page)
    if per_page_params == "all"
      result.all
    else
      result.page(params[:page])
        .per(per_page)
    end
  end

  private def pagination_links(scope)
    {
      first: page_link(1),
      next: (page_link(scope.current_page + 1) unless scope.last_page?),
      prev: (page_link(scope.current_page - 1) unless scope.first_page?),
      last: page_link(scope.total_pages)
    }
  end

  private def page_link(page)
    url_for(
      controller: controller_name,
      action: action_name,
      page:,
      per_page: (page.present? && !per_page_params.to_i.zero?) ? per_page_params.to_i : nil
    )
  end

  private def per_page_params
    @per_page_params ||= params[:per_page] || params[:perPage]
  end
end

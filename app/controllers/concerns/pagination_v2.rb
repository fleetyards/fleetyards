# frozen_string_literal: true

module PaginationV2
  extend ActiveSupport::Concern

  included do
    helper_method :per_page, :last_page?, :prev_url, :next_url
  end

  def per_page(model)
    return nil if per_page_params == "all"
    return model.default_per_page if per_page_params.blank? || per_page_params.to_i.zero? || per_page_params.to_i > model.max_per_page

    per_page_params.to_i
  end

  def last_page?(scope)
    return true if per_page_params == "all"
    return true if scope.current_page > scope.total_pages

    scope.last_page?
  end

  def prev_url(scope)
    return if per_page_params == "all"
    return if scope.first_page?

    page_link(scope.current_page - 1)
  end

  def next_url(scope)
    return if per_page_params == "all"
    return if scope.last_page? || scope.current_page > scope.total_pages

    page_link(scope.current_page + 1)
  end

  private def result_with_pagination(result, per_page)
    if per_page_params == "all"
      result.all
    else
      result.page(params[:page])
        .per(per_page)
    end
  end

  private def page_link(page)
    url_for(
      controller: controller_name,
      action: action_name,
      page:,
      per_page: page.present? && !per_page_params.to_i.zero? ? per_page_params.to_i : nil
    )
  end

  private def per_page_params
    @per_page_params ||= params[:perPage] || params[:per_page] || params[:limit]
  end
end

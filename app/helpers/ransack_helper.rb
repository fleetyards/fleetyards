# frozen_string_literal: true

module RansackHelper
  def query_params(*filters)
    # rubocop:disable Rails/HelperInstanceVariable
    @query_params ||= ActionController::Parameters.new(parse_query_params).permit(filters)
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def per_page(model)
    per_page_param = params[:perPage].to_i if params[:perPage].present?
    [(per_page_param || model.default_per_page), model.default_per_page * 4].min
  end

  def sort_by_name(fallback = 'name asc', minimum = 'name asc')
    if query_params['sorts'].present?
      sorts = query_params['sorts']
      sorts = sorts.split(',') if sorts.is_a? String
      minimum_parts = minimum.split(' ')
      sorts.push(minimum) unless sorts.include?(minimum_parts.first) || sorts.include?("#{minimum_parts.first} desc") || sorts.include?("#{minimum_parts.first} asc")
      sorts
    else
      fallback
    end
  end

  private def parse_query_params
    orginal_params = params.to_unsafe_h.fetch(:q, '{}')
    orginal_params = orginal_params.to_json if orginal_params.is_a? Hash
    q = JSON.parse(orginal_params)
    q.transform_keys(&:underscore)
  rescue JSON::ParserError
    {}
  end
end

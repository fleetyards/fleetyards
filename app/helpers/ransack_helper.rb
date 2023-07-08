# frozen_string_literal: true

module RansackHelper
  def query_params(*filters)
    ActionController::Parameters.new(parse_query_params).permit(filters)
  end

  def sort_by_name(fallback = "name asc", minimum = "name asc")
    if query_params["sorts"].present?
      sorts = query_params["sorts"]
      sorts = sorts.split(",") if sorts.is_a? String
      minimum_parts = minimum.split
      sorts.push(minimum) unless sorts.include?(minimum_parts.first) || sorts.include?("#{minimum_parts.first} desc") || sorts.include?("#{minimum_parts.first} asc")
      sorts
    else
      fallback
    end
  end

  private def parse_query_params
    orginal_params = params.to_unsafe_h.fetch(:q, "{}")
    orginal_params = orginal_params.to_json if orginal_params.is_a? Hash
    q = JSON.parse(orginal_params)
    q.transform_keys(&:underscore)
  rescue JSON::ParserError
    {}
  end
end

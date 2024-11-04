# frozen_string_literal: true

module RansackHelper
  def query_params(*filters)
    ActionController::Parameters.new(parse_query_params).permit(filters)
  end

  def sorting_params(model, fallback = nil)
    sorting_params = query_params(:sorts, sorts: []).presence || query_params(:s, s: []) || params.permit(:s, :sorts, s: [], sorts: [])

    sorts = sorting_params[:s].presence || sorting_params[:sorts].presence

    filtered_sorts = if current_user.is_a?(User)
      (sorts.is_a?(Array) ? sorts : [sorts]).filter do |sort|
        model::ALLOWED_SORTING_PARAMS.include?(sort)
      end
    else
      sorts
    end

    filtered_sorts.presence || fallback || model::DEFAULT_SORTING_PARAMS
  end

  private def parse_query_params
    orginal_params = params.to_unsafe_h.fetch(:q, "{}")
    orginal_params = orginal_params.to_json if orginal_params.is_a? Hash
    q = JSON.parse(orginal_params)
    q.transform_keys do |key|
      decamelize(key)
    end
  rescue JSON::ParserError
    {}
  end

  private def decamelize(camel_cased_word)
    camel_cased_word.split(/(?=[A-Z])/).join("_").downcase
  end
end

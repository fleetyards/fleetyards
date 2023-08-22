# frozen_string_literal: true

module RansackHelper
  def query_params(*filters)
    ActionController::Parameters.new(parse_query_params).permit(filters + [sorts: []])
  end

  def sorting_params(model, fallback = nil)
    sorting_params = query_params(:sorts, sorts: [])

    (sorting_params[:sorts].is_a?(Array) ? sorting_params[:sorts] : [sorting_params[:sorts]]).filter do |sort|
      model::ALLOWED_SORTING_PARAMS.include?(sort)
    end.presence || fallback || model::DEFAULT_SORTING_PARAMS
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

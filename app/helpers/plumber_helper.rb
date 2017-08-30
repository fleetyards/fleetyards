# frozen_string_literal: true

module PlumberHelper
  def plumb(attributes)
    url_for((@plumber ||= ::UrlPlumber::Plumber.new(params.permit!)).plumb(attributes))
  end
end

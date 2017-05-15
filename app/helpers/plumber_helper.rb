# frozen_string_literal: true

module PlumberHelper
  def plumb(attributes)
    url_for((@plumber ||= ::UrlPlumber::Plumber.new(params)).plumb(attributes))
  end
end

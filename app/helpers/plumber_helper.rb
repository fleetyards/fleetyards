module PlumberHelper

  def plumb(attributes)
    return url_for (@plumber ||= ::UrlPlumber::Plumber.new(params)).plumb(attributes)
  end
end

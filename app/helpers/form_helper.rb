module FormHelper

  def form_error?(obj, method)
    obj.errors[method].empty? ? '' : 'has-error'
  end

  def form_errors(obj, method)
    errors = obj.errors[method]
    return if errors.empty?
    content_tag(:small, errors.join(' '))
  end
end

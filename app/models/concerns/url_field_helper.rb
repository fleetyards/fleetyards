# frozen_string_literal: true

module UrlFieldHelper
  extend ActiveSupport::Concern

  def ensure_valid_url(model, field_name, force: false)
    field = model.send(field_name)

    return if field.blank?
    return field unless force || model.attribute_changed?(field_name)

    normalize_url(field)
  end

  def ensure_valid_ts_url(model, field_name, force: false)
    field = normalize_url(model.send(field_name))

    return if field.blank?
    return field unless force || model.attribute_changed?(field_name)

    "ts3server://#{field}"
  end

  private def normalize_url(url)
    return if url.blank?

    url.gsub('http:', '')
      .gsub('https:', '')
      .gsub('ts3server:', '')
      .gsub('//', '')
  end
end

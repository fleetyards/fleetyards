# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include SlugHelper

  def self.human_enum_name(enum_name, enum_value)
    return if enum_value.blank?

    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end

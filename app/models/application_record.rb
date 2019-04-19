# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include SlugHelper

  def self.human_enum_name(enum_name, enum_value)
    return if enum_value.blank?

    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  def to_jbuilder_json(*_args)
    ApplicationController.new.view_context.render(
      partial: "api/v1/#{self.class.model_name.element.pluralize}/jbuilder",
      locals: {
        self.class.model_name.element.to_sym => self
      },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end

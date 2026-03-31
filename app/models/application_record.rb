# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include SlugConcern

  def self.human_enum_name(enum_name, enum_value)
    return if enum_value.blank?

    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  def self.per_page_steps(val = :none)
    if val == :none
      # getter
      defined?(@_per_page_steps) && @_per_page_steps
    else
      # setter
      @_per_page_steps = val
    end
  end

  def jbuilder_collection_folder
    "#{self.class.model_name.collection}/#{self.class.model_name.element}"
  end

  def jbuilder_template_instance_name
    self.class.model_name.element.to_sym
  end

  def jbuilder_template_path
    "api/v1/#{jbuilder_collection_folder}"
  end

  def to_jbuilder_json(*_args)
    ApplicationController.renderer.render(
      partial: jbuilder_template_path,
      locals: {
        jbuilder_template_instance_name => self
      },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  private def update_slugs
    self.slug = generate_slug(name)
  end
end

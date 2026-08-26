# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include SlugConcern

  def self.human_enum_name(enum_name, enum_value)
    return if enum_value.blank?

    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  # The preload spec for every attachment this class declares. Unpreloaded, each
  # one costs two queries per row -- the attachment and then its blob -- so a
  # list endpoint rendering a record with twenty pictures pays forty.
  #
  # Derived rather than listed, so a new attachment is covered by the preload the
  # moment a partial starts rendering it.
  def self.attachment_preloads
    attachment_reflections.keys.map { |name| {"#{name}_attachment": :blob} }
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

  # Jbuilder builds a Hash and its template handler serializes it on the way
  # out, so this parses back what `target!` had just encoded. Driving
  # JbuilderTemplate directly and reading `attributes!` skips both steps, but
  # it is not worth it: the saving is ~7% (the cost is the nested ActionView
  # partial renders, not the serialization), and a view context built outside
  # ApplicationController.renderer carries no request, so `rails_blob_url` in
  # api/v1/shared/_file raises `undefined method 'host' for nil` as soon as the
  # record has an attachment. The renderer's fabricated env is what supplies
  # that host, and this round trip is its price.
  def to_jbuilder_hash(*_args)
    JSON.parse(to_jbuilder_json)
  end

  private def update_slugs
    self.slug = generate_slug(name)
  end
end

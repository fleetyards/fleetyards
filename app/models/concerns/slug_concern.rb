module SlugConcern
  extend ActiveSupport::Concern

  class_methods do
    # The slug an importer would end up writing, without a record to ask. The
    # loaders have to find the row a name belongs to before they build anything,
    # and a second copy of the derivation would drift from this one.
    def slug_for(value)
      return if value.blank?

      value.parameterize.presence || value
    end
  end

  def generate_slug(slug_field)
    return if slug_field.blank?

    self.slug = slug_field.parameterize

    self.class.slug_for(slug_field)
  end
end

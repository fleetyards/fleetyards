module SlugConcern
  extend ActiveSupport::Concern

  def generate_slug(slug_field)
    return if slug_field.blank?

    self.slug = slug_field.parameterize

    slug.presence || slug_field
  end
end

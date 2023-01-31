# frozen_string_literal: true

module SlugHelper
  def self.generate_slug(name)
    return if name.blank?

    slug = name.parameterize

    slug.presence || name
  end
end

# frozen_string_literal: true

module SlugHelper
  def self.generate_slug(name)
    return if name.blank?

    name.downcase.gsub(/\s/, "-")
  end
end

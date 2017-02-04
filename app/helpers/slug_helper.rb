# coding: utf-8
# frozen_string_literal: true
module SlugHelper
  def self.generate_slug(name)
    unless name.blank?
      slug = name.gsub /[ö]/, 'oe'
      slug = slug.gsub /[ü]/, 'ue'
      slug = slug.gsub /[ä]/, 'ae'
      slug = slug.gsub /[ß]/, 'ss'
      slug = slug.gsub /[Ä]/, 'Ae'
      slug = slug.gsub /[Ö]/, 'Oe'
      slug = slug.gsub /[Ü]/, 'Ue'
      slug = slug.gsub /[éèê]/, 'e'
      slug = slug.gsub /[àáâ]/, 'a'
      slug = slug.gsub /[óòô]/, 'o'
      slug = slug.gsub /[íìî]/, 'i'
      slug = slug.gsub /[ùúû]/, 'u'
      slug.parameterize
    end
  end
end

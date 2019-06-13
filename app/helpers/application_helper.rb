# frozen_string_literal: true

module ApplicationHelper
  def sortable(column, title = nil, _remote = true)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, plumb(sort: column, direction: direction, page: nil), class: css_class
  end

  def confirm_link_to(path, options = {}, &block)
    elements = []
    elements << capture(&block) if block_given?
    elements << form_for(path, url: path, method: options[:method]) { |form| } if options[:method]

    content_tag(
      :a,
      href: (options[:method].blank? ? path : '#'),
      data: options[:data],
      title: options[:title],
      class: options[:class]
    ) do
      safe_join(elements)
    end
  end

  def current_background_image
    if content_for?(:background_image)
      content_for(:background_image)
    else
      asset_path("bg-#{rand(5)}.jpg")
    end
  end

  def title
    @title ? "#{@title} | #{I18n.t(:"title.default")}" : I18n.t(:"title.default")
  end

  def description
    @description || I18n.t(:"meta.description")
  end

  def keywords
    @keywords || I18n.t(:"meta.keywords")
  end

  def og_title
    title
  end

  def og_type
    @og_type || 'website'
  end

  def og_url
    @og_url || request.original_url
  end

  def og_image
    @og_image || asset_url('icon-512.png')
  end

  def og_description
    description
  end

  def api_url(path)
    uri = URI.parse(Rails.application.secrets[:api_endpoint])

    "#{uri.scheme}://#{uri.host}#{path}"
  end
end

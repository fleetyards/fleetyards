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

    tag.a(
      href: (options[:method].blank? ? path : '#'),
      data: options[:data],
      title: options[:title],
      class: options[:class]
    ) do
      safe_join(elements)
    end
  end

  def title
    # rubocop:disable Rails/HelperInstanceVariable
    @title ? "#{@title} | #{I18n.t(:"title.default")}" : I18n.t(:"title.default")
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def description
    # rubocop:disable Rails/HelperInstanceVariable
    @description || I18n.t(:"meta.description")
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def keywords
    # rubocop:disable Rails/HelperInstanceVariable
    @keywords || I18n.t(:"meta.keywords")
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def og_title
    title
  end

  def og_type
    # rubocop:disable Rails/HelperInstanceVariable
    @og_type || 'website'
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def og_url
    # rubocop:disable Rails/HelperInstanceVariable
    @og_url || request.original_url
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def og_image
    # rubocop:disable Rails/HelperInstanceVariable
    @og_image || asset_url('icon-512.png')
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def og_description
    description
  end

  def api_url(path)
    uri = URI.parse(Rails.application.secrets[:api_endpoint])

    "#{uri.scheme}://#{uri.host}#{path}"
  end
end

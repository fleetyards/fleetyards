# frozen_string_literal: true

module ApplicationHelper
  def sortable(column, title = nil, _remote = true)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
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

  def store_url(path, options = {})
    url = "#{Rails.application.secrets[:rsi_hostname]}#{path}"
    if options[:anchor].present?
      "#{url}##{options[:anchor]}"
    else
      url
    end
  end

  def gravatar_path(size = 20, hash = nil)
    hash ||= current_user.gravatar_hash
    "//www.gravatar.com/avatar/#{hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{hash}.png&amp;r=x&amp;s=#{size}"
  end

  def current_background_image
    if content_for?(:background_image)
      content_for(:background_image)
    else
      asset_path("bg-#{rand(5)}.jpg")
    end
  end
end

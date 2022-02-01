# frozen_string_literal: true

module ButtonHelper
  def fy_btn(name, options = {}, html_options = {}, &block)
    options, html_options = name, options if block

    html_options = html_options.merge(class: fy_btn_classes(html_options))

    link_to(options, html_options) do
      fy_btn_inner(name, html_options.merge(enabled: true), &block)
    end
  end

  def fy_btn_if(condition, name, options = {}, html_options = {}, &block)
    if condition
      fy_btn(name, options, html_options, &block)
    else
      content_tag('span', html_options.merge(class: fy_btn_classes(html_options))) do
        fy_btn_inner(name, html_options.merge(enabled: false), &block)
      end
    end
  end

  private def fy_btn_inner(label = nil, options = {}, &block)
    [
      content_tag('div', '', class: fy_btn_mask_classes('-top-0.5', options)),
      content_tag('div', class: fy_btn_inner_classes(options)) do
        if block
          yield
        else
          label
        end
      end,
      content_tag('div', '', class: fy_btn_mask_classes('-bottom-0.5', options))
    ].join.html_safe # rubocop:disable Rails/OutputSafety
  end

  private def fy_btn_classes(html_options)
    css_classes = %(
      relative inline-flex items-center rounded-button bg-brand-grayBackground/90
      border-2 border-brand-grayBorder/90 p-0.5
    )

    group_css_classes = fy_btn_group_classes(html_options)
    css_classes += group_css_classes if group_css_classes.present?

    css_classes
  end

  private def fy_btn_group_classes(options = {})
    if options[:group_start]
      ' border-r border-r-neutral-700 rounded-r-none'
    elsif options[:group]
      ' border-r border-r-neutral-700 border-l-0 rounded-r-none rounded-l-none'
    elsif options[:group_end]
      ' border-l-0 rounded-l-none'
    end
  end

  private def fy_btn_inner_classes(options = {})
    css_classes = %(
      overflow-hidden rounded-md rounded-md px-3.5 py-1.5 transition-all duration-300 ease-in
    )

    if options[:disabled]
      css_classes += ' text-gray-500 cursor-default'
    elsif options[:enabled]
      css_classes += ' hover:bg-brand-grayBorder/90 hover:text-brand-grayBackground/90'
    end

    css_classes
  end

  private def fy_btn_mask_classes(extra_classes, options = {})
    css_classes = "absolute h-0.5 left-3.5 right-3.5 bg-neutral-700 #{extra_classes}"

    if options[:group_start]
      css_classes += ' -right-px'
    elsif options[:group]
      css_classes += ' -right-px left-0'
    elsif options[:group_end]
      css_classes += ' left-0'
    end

    css_classes
  end
end

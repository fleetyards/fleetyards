# frozen_string_literal: true

module NavHelper
  def active_nav?(navs = 'home')
    navs = Array(navs)
    return unless navs.any?(@active_nav)

    'active'
  end
end

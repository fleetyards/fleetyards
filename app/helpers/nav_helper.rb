# frozen_string_literal: true

module NavHelper
  def active_nav?(navs = 'home')
    navs = Array(navs)
    return unless navs.any? { |nav| nav == @active_nav }

    'active'
  end
end

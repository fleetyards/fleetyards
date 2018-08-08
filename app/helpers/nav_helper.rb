# frozen_string_literal: true

module NavHelper
  def active_nav?(navs = 'home')
    navs = [navs] unless navs.is_a?(Array)
    return unless navs.any? { |nav| nav == @active_nav }

    'active'
  end
end

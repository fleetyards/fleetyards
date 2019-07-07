# frozen_string_literal: true

module NavHelper
  def active_nav?(navs = 'home')
    navs = [navs] unless navs.is_a?(Array)
    # rubocop:disable Rails/HelperInstanceVariable
    return unless navs.any? { |nav| nav == @active_nav }

    # rubocop:enable Rails/HelperInstanceVariable
    'active'
  end
end

module NavHelper

  def get_active_nav navs = 'home'
    navs = [navs] unless navs.is_a?(Array)
    if navs.any?{|nav| active_nav?(nav)}
      return 'active'
    end
  end

  def active_nav? nav
    nav == @active_nav
  end
end

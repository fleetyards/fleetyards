module NavHelper

  def get_active_nav nav = 'home'
    if nav == @active_nav
      return "active"
    end
  end
end

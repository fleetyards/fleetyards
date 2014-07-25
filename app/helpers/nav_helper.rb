module NavHelper

  def get_active_nav nav = 'home'
    nav = nav.gsub(/\s/, '').split(',')
    if nav.include?(@active_nav)
      return "active"
    end
  end
end

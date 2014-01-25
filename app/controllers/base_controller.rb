class BaseController < ApplicationController
  skip_authorization_check
  before_filter :authenticate_user!, only: []

  def index
  end

  def update_locale
    locale = params[:new_locale]
    if locale
      if user_signed_in?
        current_user.update(locale: locale)
      end
      redirect_to root_path(locale: locale)
    else
      redirect_to root_path
    end
  end
end

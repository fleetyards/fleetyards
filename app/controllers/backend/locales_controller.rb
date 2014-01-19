module Backend
  class LocalesController < ApplicationController
    def fetch
      authorize! :update, :locales

      old_locale = I18n.locale
      I18n.available_locales.each do |locale|
        I18n.locale = locale
        WebTranslateIt.fetch_translations
        I18n.reload!
      end
      I18n.locale = old_locale

      redirect_to root_path
    end
  end
end

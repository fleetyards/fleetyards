# frozen_string_literal: true
module Backend
  class LocalesController < BaseController
    def fetch
      authorize! :update, :locales

      old_locale = I18n.locale
      I18n.available_locales.each do |locale|
        I18n.locale = locale
        WebTranslateIt.fetch_translations
        I18n.reload!
      end
      I18n.locale = old_locale

      redirect_to backend_root_path, notice: I18n.t(:"messages.reload.success", resource: I18n.t(:"resources.locale"))
    end
  end
end

# frozen_string_literal: true

module AssetHelper
  def rsi_store_url(path, options = {})
    url = "#{Rails.application.secrets[:rsi_endpoint]}#{path}"
    if options[:anchor].present?
      "#{url}##{options[:anchor]}"
    else
      url
    end
  end
end

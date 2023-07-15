# frozen_string_literal: true

class AppEndpointResolver
  def frontend_domain
    Rails.configuration.app.domain
  end

  def frontend_endpoint
    "#{scheme}://#{frontend_domain}"
  end

  def api_domain
    if Rails.configuration.app.on_subdomain?
      "api.#{Rails.configuration.app.domain}"
    else
      Rails.configuration.app.domain
    end
  end

  def api_endpoint
    if Rails.configuration.app.on_subdomain?
      "#{scheme}://#{api_domain}/#{Rails.configuration.app.api_version}"
    else
      "#{scheme}://#{api_domain}/api/#{Rails.configuration.app.api_version}"
    end
  end

  def admin_domain
    if Rails.configuration.app.on_subdomain?
      "admin.#{Rails.configuration.app.domain}"
    else
      Rails.configuration.app.domain
    end
  end

  def admin_endpoint
    if Rails.configuration.app.on_subdomain?
      "#{scheme}://#{admin_domain}"
    else
      "#{scheme}://#{admin_domain}/admin"
    end
  end

  def admin_api_endpoint
    "#{admin_endpoint}/api/#{Rails.configuration.app.admin_api_version}"
  end

  def cable_endpoint
    "#{websocket_scheme}://#{Rails.configuration.app.domain}/cable"
  end

  def docs_domain
    if Rails.configuration.app.on_subdomain?
      "docs.#{Rails.configuration.app.domain}"
    else
      Rails.configuration.app.domain
    end
  end

  def docs_endpoint
    if Rails.configuration.app.on_subdomain?
      "#{scheme}://#{docs_domain}"
    else
      "#{scheme}://#{docs_domain}/docs"
    end
  end

  private def scheme
    if Rails.configuration.force_ssl
      "https"
    else
      "http"
    end
  end

  private def websocket_scheme
    if Rails.configuration.force_ssl
      "wss"
    else
      "ws"
    end
  end
end

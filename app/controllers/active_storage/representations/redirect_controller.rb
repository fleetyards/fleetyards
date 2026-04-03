# frozen_string_literal: true

class ActiveStorage::Representations::RedirectController < ActiveStorage::Representations::BaseController
  rescue_from ActiveStorage::FileNotFoundError, with: :reprocess_representation

  def show
    reprocess_representation unless representation_exists?

    expires_in ActiveStorage.service_urls_expire_in
    redirect_to url_with_origin_param(@representation.url(disposition: params[:disposition])), allow_other_host: true
  end

  private

  def representation_exists?
    @blob.service.exist?(@representation.key)
  end

  def reprocess_representation
    @blob.variant_records.destroy_all
    set_representation
  end

  def url_with_origin_param(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || "")
    params << ["origin", request.origin.to_s]
    uri.query = URI.encode_www_form(params)

    cdn_endpoint = Rails.configuration.app.storage_cdn_endpoint
    if cdn_endpoint.present?
      cdn_uri = URI.parse(cdn_endpoint)
      uri.scheme = cdn_uri.scheme
      uri.host = cdn_uri.host
      uri.port = cdn_uri.port
    end

    uri.to_s
  end
end

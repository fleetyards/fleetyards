# frozen_string_literal: true

class ActiveStorage::Blobs::RedirectController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob

  def show
    expires_in ActiveStorage.service_urls_expire_in
    redirect_to url_with_origin_param(@blob.url(disposition: params[:disposition])), allow_other_host: true
  end

  private

  def url_with_origin_param(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || "")
    params << ["origin", request.origin.to_s]
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end

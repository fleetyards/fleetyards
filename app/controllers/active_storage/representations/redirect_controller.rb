# frozen_string_literal: true

class ActiveStorage::Representations::RedirectController < ActiveStorage::Representations::BaseController
  # The store's error classes only exist once aws-sdk-s3 has been required, which
  # ActiveStorage does lazily when it builds the S3 service. Naming them in a
  # `rescue` clause would raise NameError on a Disk-backed environment and bury
  # whatever actually went wrong.
  UNAVAILABLE_ERRORS = [
    "Aws::S3::Errors::ServiceError",
    "Seahorse::Client::NetworkingError"
  ].freeze

  rescue_from ActiveStorage::FileNotFoundError, with: :reprocess_representation

  def show
    reprocess_representation unless representation_exists?

    expires_in ActiveStorage.service_urls_expire_in
    redirect_to url_with_origin_param(@representation.url(disposition: params[:disposition])), allow_other_host: true
  end

  private

  # Only decides whether to repair a variant record whose object is gone, so a
  # store that cannot answer must not take the request with it. Redirecting on a
  # failed probe costs nothing -- signing the URL needs no round trip, and a
  # client fetching a genuinely missing object gets a 404 from the store rather
  # than a 500 from us. Answering false instead would send variant processing at
  # a store that is already failing.
  def representation_exists?
    @blob.service.exist?(@representation.key)
  rescue => error
    raise unless store_unavailable?(error)

    Rails.logger.warn("representation probe skipped, #{error.class}: #{error.message}")

    true
  end

  def store_unavailable?(error)
    UNAVAILABLE_ERRORS.any? do |name|
      klass = name.safe_constantize

      klass && error.is_a?(klass)
    end
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

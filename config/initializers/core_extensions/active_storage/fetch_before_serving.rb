# frozen_string_literal: true

# The disk controller sends a file by its path and never calls the service's
# `download`, so a service that fetches on demand has to be asked first.
module CoreExtensions
  module FetchBeforeServing
    def show
      key = decode_verified_key
      service = named_disk_service(key[:service_name]) if key
      service.fetch(key[:key]) if service.respond_to?(:fetch)

      super
    rescue ActiveStorage::InvalidKeyError
      head :not_found
    end
  end
end

Rails.application.config.to_prepare do
  ActiveStorage::DiskController.prepend(CoreExtensions::FetchBeforeServing)
end

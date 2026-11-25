# frozen_string_literal: true

require "active_storage/service/disk_service"
require "net/http"

module ActiveStorage
  # A disk service that downloads a file it does not have from `origin`, once,
  # when something reads it. Uploads and deletes only ever touch the disk, so a
  # database restored from production cannot change production's files.
  class Service::ReadThroughDiskService < Service::DiskService
    # Objects ActiveStorage names sit at the top level of the bucket. Anything
    # else has no business being requested from the origin.
    REMOTE_KEY = /\A[A-Za-z0-9]+\z/

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 60

    def initialize(root:, origin: nil, **options)
      super(root:, **options)
      @origin = origin.presence&.chomp("/")
    end

    def download(key, &block)
      fetch(key)
      super
    end

    def download_chunk(key, range)
      fetch(key)
      super
    end

    def compose(source_keys, destination_key, **)
      source_keys.each { |key| fetch(key) }
      super
    end

    # Asks without downloading: a bulk import checks every file it knows.
    def exist?(key)
      super || remote?(key)
    end

    # Puts the file on disk unless it is there already. A file the origin does
    # not have, or cannot be reached for, is left missing.
    def fetch(key)
      path = path_for(key)
      return if File.exist?(path) || !fetchable?(key)

      store(key, make_path_for(key))
    end

    private

    attr_reader :origin

    def fetchable?(key)
      origin.present? && REMOTE_KEY.match?(key)
    end

    def remote?(key)
      return false unless fetchable?(key)

      request(Net::HTTP::Head, key) { |response| response.is_a?(Net::HTTPOK) } || false
    end

    # Written beside its target and renamed, so neither a concurrent read nor
    # an interrupted download sees half a file.
    def store(key, path)
      partial = File.join(File.dirname(path), ".#{key}.#{SecureRandom.hex(4)}")

      request(Net::HTTP::Get, key) do |response|
        next unless response.is_a?(Net::HTTPOK)

        File.open(partial, "wb") { |file| response.read_body { |chunk| file.write(chunk) } }
        File.rename(partial, path)
      end
    ensure
      FileUtils.rm_f(partial) if partial
    end

    def request(verb, key)
      uri = URI.parse("#{origin}/#{key}")
      result = nil

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        # The stored size is the uncompressed one.
        http.request(verb.new(uri, "Accept-Encoding" => "identity")) { |response| result = yield(response) }
      end

      result
    rescue SocketError, SystemCallError, Timeout::Error, EOFError, OpenSSL::SSL::SSLError, Net::ProtocolError, Net::HTTPBadResponse => e
      Rails.logger.warn("[storage] could not read #{key} from #{origin}: #{e.class} #{e.message}")
      nil
    end
  end
end

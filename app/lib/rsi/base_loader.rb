require "open-uri"

module Rsi
  class BaseLoader
    attr_accessor :base_url, :graphql_client

    def initialize(options = {})
      @base_url = options[:base_url] || Rails.configuration.rsi.endpoint
      @graphql_client = Graphlient::Client.new("#{base_url}/graphql")
    end

    # A load runs against a fixture in the test environment, where the site is
    # not reachable and an attachment would be written per example. Named
    # rather than asked inline so a test that is about the fetch can allow it.
    private def fetch_images?
      !Rails.env.test?
    end

    # RSI's media entries are not consistent about it: most `source_url`s are
    # paths off the site root, but some name the media host outright. Prefixing
    # an absolute one yielded the host `robertsspaceindustries.comhttps`, which
    # `URI.parse` accepts and nothing serves, so the fetch failed for those --
    # invisibly, because `attach_image_from_url` only logs.
    private def media_url(source_url)
      return if source_url.blank?
      return source_url if source_url.start_with?("http")

      "#{base_url}#{source_url}"
    end

    private def attach_image_from_url(record, attachment_name, url)
      return if url.blank?

      uri = URI.parse(url)
      tempfile = uri.open # rubocop:disable Security/Open
      filename = File.basename(uri.path)
      content_type = Marcel::MimeType.for(name: filename)
      attachment = record.send(attachment_name)

      # Nothing is written when the remote file is the one already attached, so
      # a loader may follow a source on every run without minting a blob per
      # pass. Digested in chunks because the same method carries store images,
      # which are megabytes where a logo is kilobytes.
      return if attachment.attached? && attachment.blob.checksum == digest(tempfile)

      attachment.attach(
        io: tempfile,
        filename: filename,
        content_type: content_type
      )
    rescue => e
      Rails.logger.error "Failed to attach image #{attachment_name} for #{record.class}##{record.id}: #{e.message}"
    end

    private def digest(io)
      digest = Digest::MD5.new

      while (chunk = io.read(16.kilobytes))
        digest << chunk
      end

      io.rewind

      digest.base64digest
    end

    private def fetch_remote(url)
      response = Typhoeus.get(url)

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url: url.split("?").first)
      when 200
        log_entry = RsiRequestLog.find_by(url: url.split("?").first, resolved: false)
        log_entry.update(resolved: true) if log_entry.present?
      end

      response
    end

    private def load_data
      response = fetch_remote("#{base_url}/ship-matrix/index?#{Time.zone.now.to_i}")

      return [] unless response.success?

      begin
        JSON.parse(response.body).dig("data") || []
      rescue JSON::ParserError => e
        Appsignal.report_error(e)
        Rails.logger.error "Model Data could not be parsed: #{response.body}"
        []
      end
    end

    private def fetch_graphql(body)
      response = Typhoeus.post("#{base_url}/graphql", body:, headers: {"Content-Type" => "application/json"})

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url: "#{base_url}/graphql")
      when 200
        log_entry = RsiRequestLog.find_by(url: "#{base_url}/graphql", resolved: false)
        log_entry.update(resolved: true) if log_entry.present?

        JSON.parse(response.body)
      end

      response
    end

    private def strip_name(name)
      name.gsub(/(?:AEGIS|Aegis|ARGO|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|MIRAI|Mirai|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|CNOU|Consolidated Outland)/, "").strip
    end

    private def nil_or_decimal(value)
      return if value.blank?

      value.to_d
    end

    private def nil_or_int(value)
      return if value.blank?

      value.to_i
    end
  end
end

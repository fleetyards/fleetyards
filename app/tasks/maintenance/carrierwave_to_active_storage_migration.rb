# frozen_string_literal: true

require "open-uri"

module Maintenance
  module CarrierwaveToActiveStorageMigration
    extend ActiveSupport::Concern

    included do
      def collection
        self.class::MODEL.where(carrierwave_migrated_at: nil)
      end

      def count
        self.class::MODEL.where(carrierwave_migrated_at: nil).count
      end

      def process(record)
        self.class::FIELD_MAPPINGS.each do |carrierwave_field, active_storage_field|
          migrate_field(record, carrierwave_field, active_storage_field)
        end

        record.update_column(:carrierwave_migrated_at, Time.current)
      end
    end

    private def migrate_field(record, carrierwave_field, active_storage_field)
      uploader = record.send(carrierwave_field)
      return if uploader.blank?
      return if record.send(active_storage_field).attached?

      url = uploader.url
      return if url.blank?

      filename = File.basename(uploader.file.filename)
      content_type = Marcel::MimeType.for(name: filename)

      uri = URI.parse(url)
      tempfile = uri.open # rubocop:disable Security/Open

      record.send(active_storage_field).attach(
        io: tempfile,
        filename: filename,
        content_type: content_type
      )
    rescue => e
      puts "ERROR: #{record.class}##{record.id} #{carrierwave_field} -> #{e.message}"
    end
  end
end

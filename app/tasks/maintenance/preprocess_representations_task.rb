# frozen_string_literal: true

module Maintenance
  class PreprocessRepresentationsTask < MaintenanceTasks::Task
    def collection
      ActiveStorage::Blob.where(
        content_type: %w[image/png image/jpeg image/webp image/gif]
      ).where.not(
        id: ActiveStorage::VariantRecord.select(:blob_id)
      )
    end

    def count
      collection.count
    end

    def process(blob)
      return unless blob.representable?

      ActiveStorageVariants::REPRESENTATION_SIZES.each_value do |transformations|
        blob.representation(transformations).processed
      rescue => e
        puts "ERROR: Blob##{blob.id} (#{blob.filename}) -> #{e.message}"
      end
    end
  end
end

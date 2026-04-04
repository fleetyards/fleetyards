# frozen_string_literal: true

class PreprocessRepresentationsJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 3

  def perform(blob_id)
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob&.representable?

    ActiveStorageVariants::REPRESENTATION_SIZES.each_value do |transformations|
      blob.representation(transformations).processed
    end
  end
end

# frozen_string_literal: true

module ActiveStorageVariants
  extend ActiveSupport::Concern

  # A vector needs no variant -- it draws at any size, and ActiveStorage will
  # not process one anyway, so every size resolves to the file itself. Kept to
  # image formats: the other non-representable attachments are JSON, glTF
  # meshes and octet-stream, and handing those out as an image URL would draw a
  # broken picture where a placeholder belongs.
  VECTOR_CONTENT_TYPES = ["image/svg+xml"].freeze

  REPRESENTATION_SIZES = {
    small: {format: :webp, resize_to_limit: [500, 500], saver: {quality: 80}},
    medium: {format: :webp, resize_to_limit: [1000, 1000], saver: {quality: 82}},
    large: {format: :webp, resize_to_limit: [2000, 2000], saver: {quality: 82}},
    xlarge: {format: :webp, resize_to_limit: [3000, 3000], saver: {quality: 82}}
  }.freeze

  included do
    after_commit :preprocess_representations, if: :has_new_attachments?
  end

  def preprocess_representations
    image_attachments.each do |name|
      attachment = send(name)
      next unless attachment.attached? && attachment.representable?

      PreprocessRepresentationsJob.perform_async(attachment.blob.id)
    end
  end

  private

  def image_attachments
    self.class.reflect_on_all_attachments
      .select { |a| a.macro == :has_one_attached }
      .map(&:name)
      .select { |name| send(name).attached? && send(name).representable? }
  end

  def has_new_attachments?
    self.class.reflect_on_all_attachments
      .select { |a| a.macro == :has_one_attached }
      .map(&:name)
      .any? { |name| attachment_changes.key?(name.to_s) }
  end
end

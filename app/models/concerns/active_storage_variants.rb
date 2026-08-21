# frozen_string_literal: true

module ActiveStorageVariants
  extend ActiveSupport::Concern

  # A vector has no representations to make -- it draws at whatever size it is
  # handed -- so these are the content types that fall outside the sizes below.
  # "image/svg" is not a registered type, but it is what a hand-rolled client
  # sends, and Marcel passes a declared type through when the bytes tell it no
  # better.
  VECTOR_CONTENT_TYPES = ["image/svg+xml", "image/svg"].freeze

  REPRESENTATION_SIZES = {
    small: {format: :webp, resize_to_limit: [500, 500], saver: {quality: 80}},
    medium: {format: :webp, resize_to_limit: [1000, 1000], saver: {quality: 82}},
    large: {format: :webp, resize_to_limit: [2000, 2000], saver: {quality: 82}},
    xlarge: {format: :webp, resize_to_limit: [3000, 3000], saver: {quality: 82}}
  }.freeze

  included do
    class_attribute :trimmed_attachment_names, default: [], instance_writer: false

    after_commit :preprocess_representations, if: :has_new_attachments?
  end

  class_methods do
    # Opts an attachment into being cropped to its opaque bounds on the way in,
    # before any representation of it exists. See AttachmentTrimmer for what
    # counts as empty and why nothing without an alpha channel is touched.
    def trim_attachment(*names)
      self.trimmed_attachment_names = trimmed_attachment_names + names.map(&:to_s)
    end
  end

  # Only what this save attached: the trim re-attaches what it crops, and a
  # record with twenty views would otherwise queue every one of them again for
  # every single crop.
  def preprocess_representations
    new_attachment_names.each do |name|
      attachment = send(name)
      next unless attachment.attached? && attachment.representable?

      # Representations of the padded original would only be thrown away by the
      # crop that follows, which re-attaches and brings this callback round
      # again on the blob worth building them from.
      if trim_pending?(name)
        TrimAttachmentJob.perform_async(self.class.name, id, name)
      else
        PreprocessRepresentationsJob.perform_async(attachment.blob.id)
      end
    end
  end

  private

  def trim_pending?(name)
    return false unless trimmed_attachment_names.include?(name)

    attachment = send(name)
    attachment.attached? && attachment.blob.metadata[:trimmed].blank?
  end

  def new_attachment_names
    one_attachment_names.select { |name| attachment_changes.key?(name) }
  end

  def one_attachment_names
    self.class.reflect_on_all_attachments
      .select { |attachment| attachment.macro == :has_one_attached }
      .map { |attachment| attachment.name.to_s }
  end

  def has_new_attachments?
    new_attachment_names.any?
  end
end

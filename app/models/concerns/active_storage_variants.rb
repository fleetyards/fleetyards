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

    # Captured in `after_save` and read in `after_commit`: Rails clears
    # `attachment_changes` between the two, so asking there answers an empty
    # list and the callback below never fires at all.
    after_save :remember_new_attachments
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
      if !trim_pending?(name)
        PreprocessRepresentationsJob.perform_async(attachment.blob.id)
      elsif uploaded_attachment_names.include?(name)
        trim_now(name)
      else
        TrimAttachmentJob.perform_async(self.class.name, id, name)
      end
    end
  end

  def new_attachment_names
    @new_attachment_names || []
  end

  private

  # The crop replaces the blob, so the response is built from the padded
  # original whenever it runs behind the request -- the emblem is drawn with
  # its transparent canvas around it until something reloads the page. Doing it
  # here costs a download and a crop, and only where the bytes are already in
  # storage, which is what the trim is for.
  def trim_now(name)
    attachment = send(name)

    return if AttachmentTrimmer.new(attachment).call

    PreprocessRepresentationsJob.perform_async(attachment.blob.id)
  rescue => error
    # Deliberately broad. This runs after the record is committed, so nothing
    # here can undo the save -- an unreadable file, a storage hiccup, a decoder
    # gap -- and raising would turn a picture that could not be cropped into a
    # failed request for a record that is already written. The job is the path
    # that retries, so the work is handed back to it.
    Rails.logger.warn("Inline trim of #{self.class.name}##{id} #{name} failed: #{error.class}")
    TrimAttachmentJob.perform_async(self.class.name, id, name)
  end

  def remember_new_attachments
    @new_attachment_names = one_attachment_names.select { |name| attachment_changes.key?(name) }
    @uploaded_attachment_names = @new_attachment_names.select { |name| already_uploaded?(name) }
  end

  def uploaded_attachment_names
    @uploaded_attachment_names || []
  end

  # A signed id or a blob names a file the direct-upload endpoint has already
  # put in storage, so it can be read straight away. Anything else -- a file
  # posted with the form -- ActiveStorage uploads in an `after_commit` of its
  # own, which may not have run yet: that one has to go through the job, whose
  # retry is what waits for the bytes.
  def already_uploaded?(name)
    change = attachment_changes[name]

    # A purge is a change too, and `DeleteOne` names no attachable. Asked here
    # rather than left to the caller because this runs for every attachment the
    # save touched, before anything has decided which of them are still there.
    return false unless change.respond_to?(:attachable)

    change.attachable.is_a?(String) || change.attachable.is_a?(ActiveStorage::Blob)
  end

  def trim_pending?(name)
    return false unless trimmed_attachment_names.include?(name)

    attachment = send(name)
    attachment.attached? && attachment.blob.metadata[:trimmed].blank?
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

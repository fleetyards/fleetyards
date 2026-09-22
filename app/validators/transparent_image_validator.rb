# frozen_string_literal: true

# An emblem is drawn on whatever surface it lands on -- a card, a table row, the
# corner of an avatar -- so it has to carry its own cut-out. A JPEG, or a PNG
# flattened onto white, arrives as a rectangle and reads as a sticker stuck over
# the layout rather than as a mark belonging to it.
#
# The check is the one `AttachmentTrimmer` already makes: vips reports whether
# the image carries an alpha channel. It answers the question the content type
# cannot -- a PNG may or may not have one -- and it is cheap next to the upload
# that just happened.
class TransparentImageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    # Only what this save attaches. A record that picked up an opaque image
    # before this validation existed has to stay editable, and re-checking an
    # attachment nobody touched would make every later save of that record fail.
    change = record.attachment_changes[attribute.to_s]

    return if change.blank?

    # A purge names no attachable, and there is nothing to look at.
    return unless change.respond_to?(:attachable)
    return if transparent?(change)

    record.errors.add(attribute, :not_transparent)
  end

  # A vector is transparent by construction and has no raster alpha channel to
  # ask about. `no_vector_image` is what turns those away where they are not
  # wanted; this validator must not reject one for the wrong reason.
  private def transparent?(change)
    return true if ActiveStorageVariants::VECTOR_CONTENT_TYPES.include?(change.blob&.content_type)

    bytes = image_bytes(change)

    return true if bytes.blank?

    require "vips"

    Vips::Image.new_from_buffer(bytes, "").has_alpha?
  rescue Vips::Error, ActiveStorage::FileNotFoundError
    # Unreadable is not the same as opaque. The upload is let through and
    # whatever else validates the file decides; failing here would turn a
    # decoder gap into "your logo is not transparent", which is a lie.
    true
  end

  # The bytes, from wherever this change is carrying them. Validation runs
  # before the blob is uploaded, so `blob.download` only answers for an
  # attachable that is already in storage -- a signed id from a direct upload.
  # A file posted with the form is still a tempfile on disk.
  private def image_bytes(change)
    attachable = change.attachable

    if attachable.respond_to?(:tempfile)
      File.binread(attachable.tempfile.path)
    elsif attachable.respond_to?(:read) && attachable.respond_to?(:rewind)
      attachable.rewind
      attachable.read.tap { attachable.rewind }
    else
      change.blob.download
    end
  end
end

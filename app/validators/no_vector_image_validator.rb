# frozen_string_literal: true

# An SVG is markup, not pixels: it can carry a <script>, and a blob served
# inline runs that script on the storage origin -- which shares a registrable
# domain, and therefore the session cookie, with the app. ActiveStorage's own
# guard against this is global (`content_types_to_serve_as_binary`), so the
# moment the game export's vector artwork is allowed inline, every attachment
# an account holder can write becomes a place to park one.
#
# Hence the split: the sc_data loaders keep attaching vectors, because no
# request path reaches them, and anything a user hands us has to be a raster
# image.
class NoVectorImageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    # Only what this save attaches. A record that picked up an SVG before this
    # validation existed has to stay editable, and re-checking an attachment
    # nobody touched would make every later save of that record fail.
    change = record.attachment_changes[attribute.to_s]

    return if change.blank?

    return if attached_blobs(change).none? { |blob| ActiveStorageVariants::VECTOR_CONTENT_TYPES.include?(blob&.content_type) }

    record.errors.add(attribute, :svg_not_supported)
  end

  # A change is either an attach or a purge, and only the former names blobs.
  private def attached_blobs(change)
    return change.blobs if change.respond_to?(:blobs)
    return Array.wrap(change.blob) if change.respond_to?(:blob)

    []
  end
end

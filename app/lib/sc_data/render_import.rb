# frozen_string_literal: true

module ScData
  # Attaches the renders sc-tools publishes for one record: fetched only when
  # their MD5 is new, uploaded before they are attached, and recorded so a run
  # can skip a listing it has already taken in.
  #
  # The including job names the field each file belongs on (`field_for`), the
  # two columns the MD5s and the listing digest are kept in, and the metadata a
  # new blob starts with (`render_metadata`).
  module RenderImport
    private def import(store, record, path, digest)
      md5s = record.public_send(render_md5s_column).dup
      files = []
      complete = true

      renders(store.listing(path), path).each do |field, name, md5|
        # A render already on the record: imported before, or the same file
        # uploaded by hand, or by an import that predates the stored digests.
        if (md5s[field] == md5 || current_checksum(record, field) == md5) && stored?(record, field)
          md5s[field] = md5
          next
        end

        begin
          file = store.fetch(path, name)
        rescue => e
          log(:warn, "#{path}/#{name} could not be fetched: #{e.class}: #{e.message}")
          complete = false
          next
        end

        files << file

        if Digest::MD5.file(file.path).hexdigest != md5
          log(:warn, "#{path}/#{name} does not match its listed md5, skipped")
          complete = false
          next
        end

        # Uploaded before it is attached. Handed an io, ActiveStorage writes the
        # blob row in the save and the bytes only in an `after_commit`, so a
        # worker killed in between leaves an attachment naming a file storage
        # never received. This way a kill leaves at most an unattached blob.
        record.public_send(:"#{field}=", ActiveStorage::Blob.create_and_upload!(io: file, filename: name, metadata: render_metadata(record, field)))
        md5s[field] = md5
      end

      fields = record.attachment_changes.keys

      # A render that did not come down is fetched again next run.
      record.save!
      record.update_columns(
        render_md5s_column => md5s,
        render_digest_column => (complete ? digest : record.public_send(render_digest_column))
      )

      fields
    ensure
      files&.each(&:close!)
    end

    # [field, filename, md5] for every render with a field. Two names for one
    # field -- `side` from an older export beside `port` -- keep the first in
    # name order.
    private def renders(listing, path)
      claimed = listing.fetch("files", {})
        .sort_by(&:first)
        .map { |name, file| [field_for(name), name, file["md5"]] }
        .select(&:first)
        .group_by(&:first)

      claimed.map do |field, candidates|
        if candidates.size > 1
          log(:warn, "#{path}: #{candidates.map(&:second).join(", ")} all map to #{field}, took #{candidates.first.second}")
        end

        candidates.first
      end
    end

    # The blob row, checksum included, is written before its bytes go up, so a
    # worker killed in between leaves an attachment naming a file storage never
    # received -- and a checksum that would otherwise say it is already here.
    private def stored?(record, field)
      blob = record.public_send(field).blob

      blob.present? && blob.service.exist?(blob.key)
    end

    # ActiveStorage keeps the same MD5, base64-encoded.
    private def current_checksum(record, field)
      checksum = record.public_send(field).blob&.checksum

      checksum&.unpack1("m0")&.unpack1("H*")
    end
  end
end

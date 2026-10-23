# frozen_string_literal: true

module ScData
  # The renders sc-tools publishes under one prefix: an `index.json` naming
  # every entry with the digest of its listing, and per entry a `files.json`
  # with the MD5 of each render beside the renders themselves.
  #
  # Read only. The bucket never deletes anything, so a render missing from a
  # listing says nothing about the attachment it would have replaced.
  class RenderStore < ObjectStore
    INDEX = "index.json"
    LISTING = "files.json"

    # {"files" => {"<name>" => {"md5", "size"}}}, plus whatever the entry's
    # own kind of listing carries.
    def listing(path)
      read_json("#{path}/#{LISTING}")
    end

    # Downloads one render into a tempfile, which the caller owns.
    def fetch(path, name)
      file = Tempfile.new([prefix, File.extname(name)], binmode: true)

      with_retries do
        client.get_object(bucket:, key: key_for("#{path}/#{name}"), response_target: file.path)
      end

      file.rewind
      file
    rescue
      file&.close!
      raise
    end

    private def index
      read_json(INDEX)
    end

    private def read_json(path)
      JSON.parse(with_retries { client.get_object(bucket:, key: key_for(path)).body.read })
    end
  end
end

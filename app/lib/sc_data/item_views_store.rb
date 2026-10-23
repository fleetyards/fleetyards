# frozen_string_literal: true

module ScData
  # The item renders sc-tools publishes under `item-views/`, laid out like the
  # ship renders: an `index.json` naming every item with the digest of its
  # listing, and per item a `files.json` with the MD5 of each render beside the
  # renders themselves.
  #
  # Read only. The bucket never deletes anything, so a render missing from a
  # listing says nothing about the attachment it would have replaced.
  class ItemViewsStore < ObjectStore
    INDEX = "index.json"
    LISTING = "files.json"

    # "<path>" => {"scKey", "files", "updatedAt"}, where "scKey" is the
    # game-file key of a component or a piece of equipment.
    def items
      read_json(INDEX).fetch("items", {})
    end

    # {"files" => {"<name>" => {"md5", "size"}}}
    def listing(path)
      read_json("#{path}/#{LISTING}")
    end

    # Downloads one render into a tempfile, which the caller owns.
    def fetch(path, name)
      file = Tempfile.new(["item-view", File.extname(name)], binmode: true)

      with_retries do
        client.get_object(bucket:, key: key_for("#{path}/#{name}"), response_target: file.path)
      end

      file.rewind
      file
    rescue
      file&.close!
      raise
    end

    private def prefix
      "item-views"
    end

    private def read_json(path)
      JSON.parse(with_retries { client.get_object(bucket:, key: key_for(path)).body.read })
    end
  end
end

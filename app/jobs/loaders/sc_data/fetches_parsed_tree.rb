# frozen_string_literal: true

module Loaders
  module ScData
    # The parsed tree no longer ships in the image, so a loader job pulls the
    # environment it is about to read before touching it.
    #
    # Skipped entirely when the bucket is not configured. A developer who just
    # ran `bin/scdata parse` has the tree on disk and no credentials, and
    # loading offline has to keep working.
    #
    # The pull is incremental -- it lists the tree and fetches only what differs
    # by digest -- so running it ahead of every load costs a listing, not a
    # download, once the container is warm.
    module FetchesParsedTree
      private def fetch_parsed_tree!(version = nil)
        return unless ::ScData::ParsedStore.configured?

        store = ::ScData::ParsedStore.new(::ScData::Source.environment)

        store.verify_remote_version!(version) if version.present?

        store.pull
      end
    end
  end
end

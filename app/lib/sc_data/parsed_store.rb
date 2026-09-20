# frozen_string_literal: true

module ScData
  # Mirrors one parsed environment tree between `data/sc_data/parsed/<env>` and
  # object storage.
  #
  # The parsed tree is build input for the loader jobs, not application data --
  # nothing in the web or API path reads it, only `ScData::Loader::*`. So it is
  # kept out of git and out of the image, and the loaders container fetches the
  # single environment it is about to load.
  #
  # Both directions mirror rather than merely copy: a file the source no longer
  # carries is removed from the target. `ModelsLoader#update_in_game_flag` reads
  # a model's in-game-ness off file existence, so a leftover file from an
  # earlier build would keep a retired ship flying.
  class ParsedStore < ObjectStore
    PREFIX = "parsed"

    class VersionMismatch < StandardError; end

    attr_reader :environment

    def initialize(environment, client: nil, settings: nil)
      super(client:, settings:)

      @environment = environment.to_s
    end

    # Local -> bucket. Returns the counts of what moved.
    def push
      local = local_files

      # The mirror deletes what the source no longer carries, and since the tree
      # is no longer tracked in git, "no tree on disk" is the normal state of a
      # fresh checkout rather than an exotic one. Without this the first stray
      # `push` from one would delete the whole remote tree.
      #
      # Asked of the payload rather than of the mirror. The manifest travels
      # with the tree, so a directory holding nothing but `version.json` is not
      # empty and would walk straight past a plain `local.empty?` -- and it can
      # arrive that way by routes no parser touches: an interrupted `pull`, or a
      # tree a developer emptied by deleting its subdirectories. `report_check`
      # would also refuse such a tree, but `--force` exists to overrule the
      # verdict, and this is the one verdict nothing should be able to.
      raise MissingTree, "no tree at #{local_root}" if payload_empty?(local)

      remote = remote_objects

      uploaded = each_in_parallel(local.keys.reject { |path| remote[path]&.etag == local[path] }) do |path|
        File.open(local_path(path), "rb") do |io|
          client.put_object(bucket:, key: key_for(path), body: io)
        end
      end

      removed = each_in_parallel(remote.keys - local.keys) do |path|
        client.delete_object(bucket:, key: key_for(path))
      end

      {uploaded:, removed:, unchanged: local.size - uploaded}
    end

    # Bucket -> local. Returns the counts of what moved.
    def pull
      remote = remote_objects

      # An empty listing means a tree that was never pushed, or a wrong prefix.
      # Treating it as "nothing to download" would mirror the emptiness onto
      # disk and hand the loader a tree that retires the whole catalogue.
      #
      # Payload rather than listing, the same way round as `push`: a bucket
      # holding nothing but `version.json` is not empty, and mirroring it would
      # delete every local payload file -- which is the outcome this guard is
      # here to prevent, arriving by a route it did not cover.
      raise MissingTree, "no tree at s3://#{bucket}/#{prefix}" if payload_empty?(remote)

      local = local_files

      downloaded = each_in_parallel(remote.keys.reject { |path| local[path] == remote[path].etag }) do |path|
        download(path)
      end

      removed = each_in_parallel(local.keys - remote.keys) do |path|
        File.delete(local_path(path))
      end

      prune_empty_directories

      {downloaded:, removed:, unchanged: remote.size - downloaded}
    end

    # What the bucket's tree says about itself, straight from the
    # `version.json` the parser writes beside it. One small object, so this is
    # cheap enough to ask before deciding whether a whole load is needed.
    def remote_manifest
      @remote_manifest ||= begin
        body = client.get_object(bucket:, key: key_for(::ScData::ParsedTree::MANIFEST)).body.read

        JSON.parse(body)
      rescue Aws::S3::Errors::NoSuchKey
        {}
      end
    end

    # The version the bucket's tree says it is.
    def remote_version
      remote_manifest["version"]
    end

    # The tree's own identity, which is the question a reader deciding whether
    # to reload actually has. Blank for a tree pushed before the parser started
    # writing one.
    def remote_checksum
      remote_manifest["checksum"].presence
    end

    # The same claim, read off the tree on disk. Deliberately read rather than
    # recomputed: the digest a reader compares against is the one the parser
    # wrote, so taking it from anywhere else makes two producers for one value
    # and leaves them free to disagree.
    def local_manifest
      file = local_root.join(::ScData::ParsedTree::MANIFEST)

      return {} unless file.file?

      JSON.parse(file.read)
    rescue JSON::ParserError
      {}
    end

    def local_checksum
      local_manifest["checksum"].presence
    end

    # Pointer and payload are stored apart, so they can disagree -- a push that
    # half-finished, or a config bumped ahead of the upload. Loading a tree that
    # is not the build we think we are on would stamp every row with the wrong
    # version, so the mismatch has to stop the load rather than survive it.
    def verify_remote_version!(expected)
      found = remote_version

      return true if found == expected

      raise VersionMismatch,
        "s3://#{bucket}/#{prefix} carries #{found.inspect}, expected #{expected.inspect}"
    end

    def local_root
      Rails.root.join("data/sc_data/parsed", environment)
    end

    private def prefix
      "#{PREFIX}/#{environment}"
    end

    # Whether a listing holds nothing a loader could read. Answered from the
    # listing already in hand rather than by walking again, and `all?` on an
    # empty hash is true, so this covers the empty tree and the lone manifest
    # in one predicate.
    private def payload_empty?(files)
      files.keys.all? { |path| path == ::ScData::ParsedTree::MANIFEST }
    end

    # Relative path => MD5 hex. Every object in this tree is written
    # single-part, so a listing's ETag is the plain MD5 of the content and the
    # two sides can be diffed directly.
    #
    # The manifest is part of the mirror even though it is not part of the
    # digest: it has to travel with the tree it describes.
    private def local_files
      files = ::ScData::ParsedTree.files(local_root)
      manifest = local_root.join(::ScData::ParsedTree::MANIFEST)

      files[::ScData::ParsedTree::MANIFEST] = Digest::MD5.file(manifest).hexdigest if manifest.file?

      files
    end

    # A directory the mirror emptied is not an object anywhere, so nothing
    # deletes it. Left behind, `Dir.glob` keeps finding the folder and the tree
    # slowly fills with the shape of every build we ever pulled.
    private def prune_empty_directories
      return unless File.directory?(local_root)

      Dir.glob("**/*/", base: local_root)
        .sort_by { |path| -path.count("/") }
        .each do |path|
          full = File.join(local_root, path)

          Dir.rmdir(full) if File.directory?(full) && Dir.empty?(full)
        end
    end
  end
end

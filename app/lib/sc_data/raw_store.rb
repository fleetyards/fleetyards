# frozen_string_literal: true

module ScData
  # Fetches one raw export -- the game's own files as the exporter uploaded
  # them -- from object storage into `data/sc_data/raw/<version>`, which is what
  # `ScData::Parser::*` reads.
  #
  # Download only, and never a mirror. An export is immutable once uploaded and
  # nothing local is authoritative, so there is nothing to push back and no
  # reason to delete: a version folder is input to a parse rather than a tree
  # whose absences mean something. (`ParsedStore` removes what the source
  # dropped because `update_in_game_flag` reads in-game-ness off file existence;
  # nothing reads raw that way.)
  class RawStore < ObjectStore
    # A version folder as the exporter names it: the release, the environment it
    # was published to, and the id of the build carrying it --
    # `4.10.0-live.12519617`.
    VERSION_PATTERN = /\A(?<release>.+)-(?<environment>[a-z]+)\.(?<build>\d+)\z/

    def self.versions(client: nil, settings: nil)
      new(nil, client:, settings:).versions
    end

    # The newest export published to an environment, or nil if it has none.
    def self.latest(environment, client: nil, settings: nil)
      versions(client:, settings:)
        .rfind { |version| VERSION_PATTERN.match(version)[:environment] == environment.to_s }
    end

    attr_reader :version

    def initialize(version, client: nil, settings: nil)
      super(client:, settings:)

      @version = version
    end

    # Every export the bucket carries, oldest build first. They sit at the root
    # of the bucket, alongside the `parsed/` prefix.
    #
    # Ordered by build id alone rather than by release: the id is the game's own
    # monotonic counter, so it settles both a release that sorts oddly and two
    # environments sitting on the same release.
    def versions
      folders = []

      client.list_objects_v2(bucket:, delimiter: "/").each do |page|
        page.common_prefixes.each do |folder|
          name = folder.prefix.delete_suffix("/")

          folders << name if VERSION_PATTERN.match?(name)
        end
      end

      folders.sort_by { |name| VERSION_PATTERN.match(name)[:build].to_i }
    end

    # Bucket -> local. Returns the counts of what moved.
    def pull
      remote = remote_objects

      # An empty listing is a version that was never uploaded, or a typo in one.
      # Silently parsing whatever half-tree is on disk would stamp the resulting
      # rows with a build they do not describe.
      raise MissingTree, "no export at s3://#{bucket}/#{prefix}" if remote.empty?

      stale = remote.reject { |path, object| current?(path, object) }

      downloaded = each_in_parallel(stale.keys) { |path| download(path) }

      {downloaded:, unchanged: remote.size - downloaded}
    end

    def local_root
      Rails.root.join("data/sc_data/raw", version)
    end

    # The export is its own prefix at the root of the bucket. Guarded because a
    # blank one would list -- and start downloading -- the whole bucket.
    private def prefix
      raise ArgumentError, "no version given" if version.blank?

      version
    end

    # Whether the local copy is already this object.
    #
    # A single-part ETag is the content MD5 and decides outright. A multipart
    # one is a digest of digests that no local file can reproduce -- the export
    # carries a handful of them, `Data/Game2.dcb` at 331 MB among them -- so
    # comparing digests there would re-download the largest files in the export
    # on every run, and the byte count stands in instead.
    private def current?(path, object)
      full = local_path(path)

      return false unless File.file?(full)
      return File.size(full) == object.size if object.multipart?

      Digest::MD5.file(full).hexdigest == object.etag
    end
  end
end

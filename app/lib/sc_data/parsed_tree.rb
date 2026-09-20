# frozen_string_literal: true

module ScData
  # What a parsed tree *is*, as one string.
  #
  # The build version names the game export, not the tree we derive from it. A
  # parser change rewrites the tree without moving the version, and everything
  # that keys on the version then goes on serving the old one: CI through its
  # cache key, and `ScData::CheckJob` by deciding the version was already
  # loaded. Both were papered over by hand -- a `vN` prefix somebody had to
  # remember to bump, and a load somebody had to trigger.
  #
  # So the tree carries a digest of its own contents, written into
  # `version.json` by the parser, and everything that has to ask "is this the
  # tree I already have?" asks that instead.
  module ParsedTree
    # The manifest is left out of the digest it carries. It holds the digest,
    # so counting it would be circular, and its `parsed_at` moves on every
    # parse -- which would make two identical trees look different.
    MANIFEST = "version.json"

    class Empty < StandardError; end

    module_function

    # Whoever parses computes this and ships it inside the tree, so it never
    # has to be reproducible on another machine. That is deliberate: it frees
    # the parsers from having to write byte-identical output under a different
    # `Dir.glob` order, and the digest still moves whenever the content does.
    def checksum(root)
      Digest::SHA256.hexdigest(
        files(root).sort.map { |path, digest| "#{path}:#{digest}" }.join("\n")
      )
    end

    def files(root)
      return {} unless File.directory?(root)

      Dir.glob("**/*", base: root).each_with_object({}) do |path, digests|
        next if path == MANIFEST

        full = File.join(root, path)

        next unless File.file?(full)

        digests[path] = Digest::MD5.file(full).hexdigest
      end
    end
  end
end

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

    # Nil rather than the digest of nothing. `SHA256("")` is a real-looking
    # answer to "which tree is this?" for a tree that is not there, and it
    # would be recorded and compared as though it meant something -- where nil
    # falls into the "cannot tell" guard every reader already has.
    #
    # The caller may pass a walk it has already done: a parse and a push both
    # have every digest in hand, and re-walking 15k files to say the same thing
    # is the sort of cost that gets noticed later and not explained.
    def checksum(root, files = files(root))
      return if files.empty?

      # Length-prefixed, because the value's whole job is to be unambiguous. A
      # `path:digest` line joined by newlines can be forged: a path carrying a
      # newline serialises exactly as two shorter entries would, so two
      # different trees could answer the same digest -- and a collision here
      # means a tree that changed reads as one that did not, which is the one
      # failure this whole mechanism exists to prevent.
      records = files.sort.map { |path, digest| "#{path.bytesize}:#{path}#{digest}" }

      Digest::SHA256.hexdigest(records.join)
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

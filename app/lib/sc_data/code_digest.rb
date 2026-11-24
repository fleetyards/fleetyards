# frozen_string_literal: true

require "ripper"

module ScData
  # Which of our own code read a build, as one string: the parsers that wrote its
  # tree and the loaders that wrote its rows. Two builds read by the same code
  # differ because the game does; two read by different code may not.
  #
  # The files alone, not what they call elsewhere, so an equal digest is strong
  # evidence rather than proof.
  module CodeDigest
    SAME = "same"
    DIFFERENT = "different"
    UNKNOWN = "unknown"
    RELATIONS = [SAME, DIFFERENT, UNKNOWN].freeze

    module_function

    def parser
      of("parser")
    end

    def loader
      of("loader")
    end

    # What a load of this source on this checkout would be read by. Nil for a tree
    # parsed before its manifest named the parser.
    def current(source)
      written_by = ::ScData::ParsedStore.new(source.environment).local_manifest["parser"].presence

      written_by && "#{written_by}-#{loader}"
    end

    # A load of part of a build writes rows among those another code wrote. The
    # build then has no one code to name, unless it is the same one.
    def partial_load!(source = ::ScData::Source.current)
      import = ::Imports::ScData::AllImport.last_finished_for(source)
      return if import.nil? || import.code_digest.blank? || import.code_digest == current(source)

      import.update!(code_digest: nil)
    end

    # How two builds were read. Unknown for a build loaded before this was kept,
    # and for one whose rows more than one code wrote.
    def relation(from, to)
      digests = [from, to].map { |source| digest_of(source) }
      return UNKNOWN if digests.any?(&:nil?)

      digests.uniq.one? ? SAME : DIFFERENT
    end

    def digest_of(source)
      import = ::Imports::ScData::AllImport.last_finished_for(source)
      return if import.nil? || import.code_digest.blank?

      import.code_digest unless rewritten_since?(import)
    end

    # A later load that reached its loaders and did not finish left rows behind.
    # It names its tree just before they run, so one without it wrote nothing.
    def rewritten_since?(import)
      ::Imports::ScData::AllImport
        .where(version: import.version).where.not(aasm_state: "finished")
        .where(created_at: import.created_at..)
        .where("input ->> 'tree_checksum' IS NOT NULL")
        .any? { |later| later.code_digest != import.code_digest }
    end

    INSIGNIFICANT = %i[on_comment on_embdoc_beg on_embdoc on_embdoc_end on_sp on_nl on_ignored_nl].freeze

    # The code without its comments and layout, which change nothing it reads.
    def of(folder)
      root = ::Rails.root.join("app/lib/sc_data", folder)

      Digest::SHA256.hexdigest(Dir.glob("**/*.rb", base: root).sort.map { |file|
        tokens = Ripper.lex(root.join(file).read).reject { |token| INSIGNIFICANT.include?(token[1]) }

        "#{file}:#{Digest::MD5.hexdigest(tokens.map { |token| token[2] }.join("\0"))}"
      }.join("\n"))
    end
  end
end

# frozen_string_literal: true

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

    # How two builds were read. Unknown for a build loaded before this was kept.
    def relation(from, to)
      digests = [from, to].map { |source| ::Imports::ScData::AllImport.last_finished_for(source)&.code_digest.presence }
      return UNKNOWN if digests.any?(&:nil?)

      digests.uniq.one? ? SAME : DIFFERENT
    end

    def of(folder)
      root = ::Rails.root.join("app/lib/sc_data", folder)
      files = Dir.glob("**/*.rb", base: root).sort

      Digest::SHA256.hexdigest(files.map { |file| "#{file}:#{Digest::MD5.file(root.join(file)).hexdigest}" }.join("\n"))
    end
  end
end

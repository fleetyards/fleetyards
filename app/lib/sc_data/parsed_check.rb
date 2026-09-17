# frozen_string_literal: true

require "json"

module ScData
  # Whether a parsed tree is fit to be pushed and loaded.
  #
  # A parse is a long walk over an export nobody here controls, and every way it
  # can go wrong is quiet: a half-finished upload parses into a tree that is
  # merely small, a category the export renamed parses into a folder that is
  # merely empty, and a record naming its artwork with the other separator
  # parses into a path that merely never resolves. Each of those loads without
  # raising, and what it retires only shows up in the catalogue days later.
  #
  # So this asks the questions a person asks after a parse, in the one place
  # where the answer still costs nothing: before the tree replaces the one in
  # the bucket. It reads the tree and nothing else -- no network, no database --
  # which is what lets the same check run from `bin/scdata check`, before a
  # push, and as a test over the tree CI pulled.
  #
  # What it deliberately does not judge is drift. A build that drops eleven
  # ships has dropped eleven ships, and no threshold here can tell that from a
  # mistake -- `ScData::BuildCompare` answers that question against loaded rows,
  # where both builds are present and a person can read the list.
  class ParsedCheck
    DEFAULT_BASE_FOLDER = Rails.root.join("data/sc_data").freeze

    # Per catalogue: the field that identifies a record, the smallest number of
    # files a build could honestly produce, and whether a loader goes looking
    # for the artwork a record names.
    Catalogue = Struct.new(:key, :floor, :icons)

    # Blueprints name no artwork of their own: 1606 of the 1607 records in
    # 4.10.1 carry no name either, and both come from whatever the recipe makes.
    #
    # Equipment is the other catalogue whose icons go unchecked. It names artwork
    # under `ui/textures/ea/loadouticons` that the export ships none of -- all
    # 2,042 references resolve to nothing, in every build -- and nothing loads
    # them either, since `EquipmentLoader` attaches no icon. Checking them would
    # report a gap nobody can close and bury the ones that matter.
    #
    # The floors sit about a fifth below what 4.10.1-live parses to. That is
    # wide enough that no patch will reach one -- the largest move on record is
    # 4.9.0 to 4.10.0, which changed items by under a percent -- and narrow
    # enough to catch the failures that produce a tree rather than an error: an
    # export whose upload was still running, a parse that died between
    # catalogues, a sync that fetched half a prefix.
    CATALOGUES = {
      "blueprints" => Catalogue.new(key: "key", floor: 1280, icons: false),
      "commodities" => Catalogue.new(key: "sc_key", floor: 180, icons: true),
      "equipment" => Catalogue.new(key: "key", floor: 3800, icons: false),
      "items" => Catalogue.new(key: "key", floor: 6200, icons: true),
      "manufacturers" => Catalogue.new(key: "code", floor: 90, icons: true),
      "models" => Catalogue.new(key: "key", floor: 880, icons: false)
    }.freeze

    # A record may name art the export does not ship -- eight manufacturers are
    # in exactly that position, which is why an admin uploaded their logos by
    # hand. That is the game's omission and not a broken parse, so it is counted
    # rather than failed, up to the point where the count stops describing
    # individual records and starts describing a missing icons folder.
    ICON_TOLERANCE = 0.05

    Result = Struct.new(:problems, :stats) do
      def ok?
        problems.empty?
      end
    end

    attr_reader :environment, :base_folder

    def initialize(environment = ::ScData::Source.environment, base_folder: DEFAULT_BASE_FOLDER, expected_version: nil, floors: {})
      @environment = environment.to_s
      @base_folder = Pathname(base_folder)
      @expected_version = expected_version
      @floors = floors.transform_keys(&:to_s)
    end

    def call
      return Result.new(["no parsed tree at #{root}"], {}) unless root.directory?

      problems = version_problems
      stats = {}

      CATALOGUES.each do |folder, catalogue|
        folder_problems, folder_stats = check_catalogue(folder, catalogue)

        problems.concat(folder_problems)
        stats[folder] = folder_stats
      end

      problems.concat(empty_file_problems)

      Result.new(problems, stats)
    end

    def root
      base_folder.join("parsed", environment)
    end

    # The build this tree claims to be. A tree carrying the wrong one is the
    # failure that outlives every other: the pointer in the config and the files
    # in the bucket disagree, so a load stamps rows of one build with the
    # version of another and nothing ever says so.
    private def version_problems
      file = root.join("version.json")

      return ["no version.json at #{file}"] unless file.file?

      data = JSON.parse(file.read)

      return ["version.json holds #{data.class.name.downcase}, not a record"] unless data.is_a?(Hash)

      problems = []

      if data["environment"] != environment
        problems << "version.json names environment #{data["environment"].inspect}, not #{environment.inspect}"
      end

      if expected_version.present? && data["version"] != expected_version
        problems << "version.json names build #{data["version"].inspect}, while #{environment} is configured for #{expected_version.inspect}"
      end

      problems
    rescue JSON::ParserError => e
      ["version.json does not parse: #{e.message}"]
    end

    private def check_catalogue(folder, catalogue)
      files = Dir.glob(root.join(folder, "*.json"))
      floor = @floors.fetch(folder, catalogue.floor)
      stats = {files: files.size, icons_named: 0, icons_absent: 0}

      return [["#{folder}: no files at all"], stats] if files.empty?

      problems = []

      if files.size < floor
        problems << "#{folder}: #{files.size} files, short of the #{floor} a build produces"
      end

      files.each do |file|
        data = JSON.parse(File.read(file))

        # Valid JSON that is not a record at all -- `null`, a bare list -- would
        # otherwise take every key it is asked for as a method call and raise
        # from inside a check whose whole job is to report rather than raise.
        unless data.is_a?(Hash)
          problems << "#{folder}/#{File.basename(file)}: holds #{data.class.name.downcase}, not a record"
          next
        end

        if data[catalogue.key].to_s.strip.empty?
          problems << "#{folder}/#{File.basename(file)}: no #{catalogue.key}"
        end

        next unless catalogue.icons

        icon = data["icon"]

        next if icon.to_s.strip.empty?

        stats[:icons_named] += 1

        # A path the file system cannot express is ours to fix and not the
        # export's: whatever the record names, what was written next to it has
        # to be findable from it.
        if icon.include?("\\")
          problems << "#{folder}/#{File.basename(file)}: icon path #{icon.inspect} is not a path this tree can hold"
        elsif !icon_present?(icon)
          stats[:icons_absent] += 1
        end
      rescue JSON::ParserError => e
        problems << "#{folder}/#{File.basename(file)}: does not parse: #{e.message}"
      end

      if stats[:icons_named].positive? && stats[:icons_absent] > stats[:icons_named] * ICON_TOLERANCE
        problems << "#{folder}: #{stats[:icons_absent]} of #{stats[:icons_named]} named icons are not in the tree"
      end

      [problems, stats]
    end

    # Resolved the way `BaseLoader#parsed_icon` resolves it: a record names the
    # source art it was drawn from, and the tree holds whichever format the
    # export actually ships.
    private def icon_present?(icon)
      Dir.glob(root.join("icons", "#{icon.sub(/\.\w+\z/, "")}.*")).any?
    end

    # A file of no bytes is the shape a transfer takes when it stops halfway,
    # and it is the one thing here that a floor cannot catch: the count is
    # right, the tree loads, and one record or one icon is simply gone.
    private def empty_file_problems
      empty = Dir.glob(root.join("**", "*")).select { |path| File.file?(path) && File.empty?(path) }

      empty.map { |path| "#{Pathname(path).relative_path_from(root)}: empty file" }
    end

    private def expected_version
      @expected_version ||= ::ScData::Source.find(environment)&.version
    end
  end
end

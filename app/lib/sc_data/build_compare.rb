# frozen_string_literal: true

module ScData
  # What one build has that another does not, for any catalogue that records
  # builds.
  #
  # Computed rather than recorded, and that is the point of doing this half
  # first: every catalogue retains `BUILDS_RETAINED` builds per environment, so
  # the two sides of a comparison are both present and the answer is a join. Only
  # history that has to outlive those retained builds needs a table --
  # `ModelBuildChange` is that, for models, within one environment.
  #
  # This is the axis that recorder cannot reach: it diffs a build against the one
  # before it in the *same* environment and so never answers "what does ptu have
  # that live does not", which is the question a preview cycle exists to ask.
  #
  # See docs/exec-plans/sc-data-build-compare.md.
  class BuildCompare
    # A record the newer build describes and the older one does not, and the
    # reverse. `vanished` means "has no row for the newer build" rather than
    # "was deleted": a catalogue row the export drops keeps its row and loses its
    # build, the same distinction the loadout work settled for slots.
    Result = Struct.new(:appeared, :vanished, :changed, :recorded) do
      def counts
        {appeared: appeared.size, vanished: vanished.size, changed: changed.size}
      end

      alias_method :recorded?, :recorded
    end

    Change = Struct.new(:id, :name, :fields)

    attr_reader :build_class, :from, :to

    def initialize(build_class, from:, to:)
      @build_class = build_class
      @from = from
      @to = to
    end

    def call
      # A catalogue with no rows at all on one side was not *recorded* for that
      # build, which is a different statement from "everything appeared" -- and
      # reporting the lists would make it the wrong one. Commodities and models
      # only gained build rows in 4.10.0, so comparing 4.9.0 against it would
      # otherwise announce all 232 commodities and all 215 models as new.
      #
      # The lists are empty rather than merely flagged, so a reader that ignores
      # the flag still cannot draw the wrong conclusion.
      return Result.new([], [], [], false) unless recorded?

      Result.new(appeared, vanished, changed, true)
    end

    def recorded?
      from_rows.any? && to_rows.any?
    end

    # The record a build describes, derived from the one required `belongs_to`
    # rather than passed in. Every build class has exactly one; the optional ones
    # -- `manufacturer` on equipment and components, `component` on a hardpoint
    # -- are facts about the record, not the record itself.
    def self.subject_key(build_class)
      build_class
        .reflect_on_all_associations(:belongs_to)
        .reject { |association| association.options[:optional] }
        .sole
        .foreign_key
    end

    # Prose. Left out for the same reason the shapes are: it changes constantly
    # and says nothing a reader came for. Measured on live 4.9.0 against 4.10.0,
    # components: **2,171** of the 2,182 changed rows differed on `description`
    # alone, against 10 on `name` -- so including it turns a page of 350 real
    # changes into one of 2,182.
    #
    # `ModelBuild` never had this problem: it carries no description at all,
    # which is why the change log it feeds has never needed the exclusion.
    PROSE_FACTS = %i[description].freeze

    # What a comparison looks at. `ModelBuild` names its own list because it was
    # tuned by hand for the change log; the others derive it, so a fact added to
    # `FACTS` is compared without anyone remembering to say so.
    #
    # Serialized columns are left out either way. Two loads of the same export
    # can serialise a shape differently with nothing having changed, so comparing
    # them reports a difference on every re-parse -- and even a real one reads as
    # "something inside this changed", which buries the answers a person came
    # for. Measured on the same pair: 420 components differed on `type_data`.
    def self.diffable_facts(build_class)
      return build_class::DIFFABLE_FACTS if build_class.const_defined?(:DIFFABLE_FACTS)

      build_class::FACTS
        .reject { |fact| serialized?(build_class, fact) }
        .reject { |fact| PROSE_FACTS.include?(fact) }
    end

    def self.serialized?(build_class, fact)
      build_class.type_for_attribute(fact).is_a?(ActiveRecord::Type::Serialized)
    end

    private def subject_key
      @subject_key ||= self.class.subject_key(build_class)
    end

    private def facts
      @facts ||= self.class.diffable_facts(build_class)
    end

    private def appeared
      to_rows.keys - from_rows.keys
    end

    private def vanished
      from_rows.keys - to_rows.keys
    end

    private def changed
      (to_rows.keys & from_rows.keys).filter_map do |id|
        before = from_rows[id]
        after = to_rows[id]

        differing = facts.select { |fact| before[fact.to_s] != after[fact.to_s] }

        next if differing.empty?

        Change.new(id:, name: after["name"], fields: differing)
      end
    end

    # Both sides are read once and compared in Ruby rather than joined in SQL:
    # the sets are thousands of rows, the comparison needs every diffable column
    # anyway, and a self-join on a table this size buys nothing over two index
    # scans on `(environment, version)`.
    private def from_rows
      @from_rows ||= rows_for(from)
    end

    private def to_rows
      @to_rows ||= rows_for(to)
    end

    private def rows_for(source)
      columns = ([subject_key] + facts.map(&:to_s) + ["name"]).uniq
        .select { |column| build_class.column_names.include?(column) }

      build_class
        .where(environment: source.environment, version: source.version)
        .pluck(*columns)
        .to_h { |values| [values.first, columns.zip(values).to_h] }
    end
  end
end

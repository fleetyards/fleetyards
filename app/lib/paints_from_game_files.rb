# frozen_string_literal: true

# Creates the paints the game ships but RSI has not listed, so a ship's
# catalogue carries every livery it can wear rather than only the ones sold.
#
# Which ships a livery belongs to comes from the game's own fitting rule, not
# from its name: the livery requires tags ("Paint_Galaxy") that a ship's paint
# port offers, and the port in turn requires tags the livery carries. A series
# sharing one port tag gets the livery on every variant, the same way a paint
# RSI lists for a series lands on each of its models.
#
# The name is the game's minus the ship it opens with and the "Livery" suffix,
# spelled the way the store spells it, so a later RSI import finds this paint
# by name instead of adding a second one beside it. A ship that already has a
# paint reading as the same one is left alone.
class PaintsFromGameFiles
  FOUNDATION = /\bfoundation\s+(?:fest|guide)\z/i
  CAMO = /\s+camo\z/i
  BEST_IN_SHOW = /\A(\d{4})\s+(best\s+in\s+show)\z/i

  # Shorter than this, an existing name would be the tail of almost any other.
  MIN_SUFFIX_LENGTH = 5
  MIN_INNER_WORD_LENGTH = 4

  def run
    ports = fitting_ports

    current_components.find_each do |component|
      create_for(component, ports)
    rescue => e
      report(e, "paints for component #{component.id} could not be created")
    end
  end

  private def current_components
    Component.where(category: "paints").where.not(name: [nil, ""]).joins(:build)
  end

  # Only the game's own slots, in the build being served: a matrix slot names
  # no tags, and a slot the build dropped fits nothing.
  private def fitting_ports
    Hardpoint.in_build
      .where(parent_type: "Model", source: :game_files)
      .where.not(port_tags: [nil, "", "[]"])
      .includes(:parent)
      .select { |port| port.parent.present? }
  end

  private def create_for(component, ports)
    required = Array(component.required_tags)
    # A livery that asks for no tag would fit every port there is.
    return if required.empty?

    tags = Array(component.tags)

    models = ports.select { |port|
      (required - Array(port.port_tags)).empty? && (Array(port.required_tags) - tags).empty?
    }.map(&:parent).uniq

    models.each do |model|
      name = paint_name(component.name, model)
      next if name.blank?
      next if linked?(model, component)
      next if known?(model, name)

      ModelPaint.create!(model:, name:, component:, hidden: false, active: true)
      existing_names(model) << comparable(name)
    end
  end

  # The game opens with the ship as it names it, which is not always the
  # model's name: "C8 Pisces" for the C8R, "Vanguard" for the Vanguard
  # Hoplite, "Hercules Starlifter" for the C2, which only its game key spells
  # out. So opening words are dropped for as long as each reads as part of the
  # model's name, slug or game key, keeping at least one; a name whose first
  # word reads as no part of the model is left alone rather than guessed at.
  private def paint_name(component_name, model)
    words = component_name
      .sub(PaintComponentMatcher::PARENTHETICAL, "")
      .sub(PaintComponentMatcher::LIVERY_SUFFIX, "")
      .split

    ship_words = "#{model.name} #{model.slug} #{model.sc_key}".split(/[^A-Za-z0-9]+/)
      .map { |word| PaintComponentMatcher.normalize(word) }
      .compact_blank

    count = 0
    count += 1 while count < words.size - 1 && ship_word?(words[count], ship_words)

    return if count.zero?

    # "100 Series Flame Livery" names the series, not the 100i.
    rest = words.drop(count)
    rest = rest.drop(1) if rest.first.casecmp?("series") && rest.size > 1

    store_spelling(rest.join(" "))
  end

  # A word inside a ship word counts too, so "Star Fighter" reads as
  # "starfighter" -- but only a long one, or "a" would be inside everything.
  private def ship_word?(word, ship_words)
    normalized = PaintComponentMatcher.normalize(word)
    return false if normalized.blank?

    ship_words.any? do |ship_word|
      ship_word.start_with?(normalized) || (normalized.length >= MIN_INNER_WORD_LENGTH && ship_word.include?(normalized))
    end
  end

  # The store calls every Foundation paint "Foundation Festival", puts the
  # year after "Best in Show" where the game puts it in front, and drops the
  # year the game puts in front of its Auspicious paints.
  private def store_spelling(name)
    spelled = name.sub(FOUNDATION, "Foundation Festival").sub(BEST_IN_SHOW, '\\2 \\1')

    PaintsImporter.paint_mapping(spelled).strip
  end

  # The store keeps "Camo" on some paints and drops it on others, puts a year
  # or a series in front of some names and a word after others ("Draco Gold"
  # for the game's "Draco"), so a ship already carries this paint when any of
  # its names ends with the other, or opens with it word for word.
  private def known?(model, name)
    candidates = [name, name.sub(CAMO, "")].map { |value| comparable(value) }

    existing_names(model).any? do |existing|
      candidates.any? do |candidate|
        joined = candidate.delete(" ")
        existing_joined = existing.delete(" ")

        existing_joined == joined ||
          (existing_joined.length >= MIN_SUFFIX_LENGTH && joined.end_with?(existing_joined)) ||
          (joined.length >= MIN_SUFFIX_LENGTH && existing_joined.end_with?(joined)) ||
          (joined.length >= MIN_SUFFIX_LENGTH && existing.start_with?("#{candidate} "))
      end
    end
  end

  # Lowercase words with their punctuation gone, so either spelling of a
  # name compares the same while word boundaries survive. Either order of a
  # Best in Show year is the same paint.
  private def comparable(name)
    name.sub(BEST_IN_SHOW, '\\2 \\1').split
      .map { |word| PaintComponentMatcher.normalize(word) }
      .compact_blank
      .join(" ")
  end

  # RSI's name for a paint can differ from the game's entirely -- "Red Alert"
  # is sold as "Best in Show 2952 (Red Alert)" -- so a ship whose paint the
  # linker already tied to this livery has it, whatever the name says.
  private def linked?(model, component)
    @linked ||= ModelPaint.where.not(component_id: nil).pluck(:model_id, :component_id).to_set

    @linked.include?([model.id, component.id])
  end

  private def existing_names(model)
    @existing_names ||= ModelPaint.pluck(:model_id, :name)
      .group_by(&:first)
      .transform_values { |rows| rows.map { |_, name| comparable(name) }.to_set }

    @existing_names[model.id] ||= Set.new
  end

  private def report(error, message)
    Appsignal.report_error(error)
    Rails.logger.error("[#{self.class.name}] #{message}: #{error.class}: #{error.message}")
  end
end
